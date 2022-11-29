/*
codeunit 87210 "wan Purch. Rcpt. not Inv."
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Batch", 'OnBeforeUpdateAndDeleteLines', '', false, false)]
    local procedure OnBeforeUpdateAndDeleteLines(var GenJournalLine: Record "Gen. Journal Line"; CommitIsSuppressed: Boolean; var IsHandled: Boolean)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        DateFormula1D: DateFormula;
    begin
        if CommitIsSuppressed then
            exit;
        GenJnlTemplate.Get(GenJournalLine."Journal Template Name");
        if not GenJnlTemplate.Recurring then
            exit;
        Evaluate(DateFormula1D, '<1D>');
        if GenJournalLine.FindSet() then
            repeat
                if (GenJournalLine."Recurring Method" = GenJournalLine."Recurring Method"::"RV Reversing Variable") and
                    (GenJournalLine."Recurring Frequency" = DateFormula1D) and
                    (GenJournalLine."Posting Date" = GenJournalLine."Expiration Date") then
                    GenJournalLine.Delete(true);
            until GenJournalLine.Next() = 0;

        IsHandled := GenJournalLine.IsEmpty;
    end;
}
*/