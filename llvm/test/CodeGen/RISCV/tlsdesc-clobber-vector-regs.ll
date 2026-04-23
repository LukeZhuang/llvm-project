; RUN: llc -mtriple=riscv64 -mattr=+v -relocation-model=pic -enable-tlsdesc < %s \
; RUN:     | FileCheck %s
; RUN: llc -mtriple=riscv32 -mattr=+v -relocation-model=pic -enable-tlsdesc < %s \
; RUN:     | FileCheck %s

;; Verify that when the V extension is enabled, vector registers whose live
;; ranges span a TLSDESC call are spilled and reloaded, because the TLSDESC
;; resolver clobbers all vector registers per the psABI.

@tls_var = external thread_local global i32

define void @test_vector_reg_clobber() nounwind {
; CHECK-LABEL: test_vector_reg_clobber:
; CHECK-DAG: vs{{[0-9]+}}r.v v2
; CHECK-DAG: vs{{[0-9]+}}r.v v3
; CHECK: jalr t0,{{.*}}%tlsdesc_call
; CHECK-DAG: vl{{[0-9]+}}r.v v2
; CHECK-DAG: vl{{[0-9]+}}r.v v3
entry:
  %v2 = call <vscale x 2 x i32> asm sideeffect "# def v2", "={v2}"()
  %v3 = call <vscale x 2 x i32> asm sideeffect "# def v3", "={v3}"()

  store i32 1, ptr @tls_var

  call void asm sideeffect "# use v2", "{v2}"(<vscale x 2 x i32> %v2)
  call void asm sideeffect "# use v3", "{v3}"(<vscale x 2 x i32> %v3)
  ret void
}
