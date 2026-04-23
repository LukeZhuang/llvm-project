; RUN: llc -mtriple=riscv64 -mattr=+v -relocation-model=pic -enable-tlsdesc < %s \
; RUN:     | FileCheck %s
; RUN: llc -mtriple=riscv32 -mattr=+v -relocation-model=pic -enable-tlsdesc < %s \
; RUN:     | FileCheck %s

;; Verify that when the V extension is enabled, the TLSDESC resolver clobbers
;; vector CSRs (vl, vtype, vxrm, vxsat) per the psABI.  The compiler must
;; re-emit a vsetvl after the TLSDESC call to recover the vector configuration

@tls_var = external thread_local global i32

define void @test_vector_csr_clobber(ptr %in, ptr %out) nounwind {
; CHECK-LABEL: test_vector_csr_clobber:
; CHECK: vsetivli zero, 4, e32, m1
; CHECK: vle32.v
; CHECK: vse32.v
; CHECK: jalr t0,{{.*}}%tlsdesc_call
; CHECK: vsetivli zero, 4, e32, m1
; CHECK: vle32.v
; CHECK: vse32.v
entry:
  %v1 = load <4 x i32>, ptr %in
  store <4 x i32> %v1, ptr %out

  store i32 1, ptr @tls_var

  ;; We must re-emit vsetvli here because TLSDESC clobbered it
  %v2 = load <4 x i32>, ptr %in
  store <4 x i32> %v2, ptr %out
  ret void
}
