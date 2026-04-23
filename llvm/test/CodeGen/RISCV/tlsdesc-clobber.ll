; RUN: llc -mtriple=riscv64 -relocation-model=pic -enable-tlsdesc < %s \
; RUN:     | FileCheck %s
; RUN: llc -mtriple=riscv32 -relocation-model=pic -enable-tlsdesc < %s \
; RUN:     | FileCheck %s

;; Verify that without the V extension, the TLSDESC resolver only clobbers a0
;; and t0 per the psABI.  Arguments in a1-a3 need not be saved/restored across
;; the TLSDESC call, unlike a normal function call.

@tls_var = external thread_local global i32

define i64 @test_clobber(i64 %a, i64 %b, i64 %c, i64 %d) nounwind {
; CHECK-LABEL: test_clobber:
; CHECK: jalr t0,{{.*}}%tlsdesc_call

;; a1-a3 need not be saved to stack or moved to s-regs.
; CHECK-NOT: {{(sw|sd)}} a{{[1-3]}},
; CHECK-NOT: mv s{{[0-9]+}}, a{{[1-3]}}
entry:
  store i32 1, ptr @tls_var
  %sum1 = add i64 %a, %b
  %sum2 = add i64 %sum1, %c
  %sum3 = add i64 %sum2, %d
  ret i64 %sum3
}
