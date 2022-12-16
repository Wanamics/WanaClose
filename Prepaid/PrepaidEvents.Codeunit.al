codeunit 87220 "wan Prepaid Events"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", 'OnAfterCheckGenJnlLine', '', false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ErrorMessageMgt: Codeunit "Error Message Management")
    var
        BothOrNoneErr: Label 'and %1 must be both filled or none';
        GLAccount: Record "G/L Account";
    begin
        if GenJournalLine."Account Type" <> GenJournalLine."Account Type"::"G/L Account" then
            exit;
        if not (GenJournalLine."Gen. Posting Type" in [GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Gen. Posting Type"::Sale]) then
            exit;
        if (GenJournalLine."Deferral Code" <> '') then begin
            GenJournalLine.TestField("wan Starting Date");
            GenJournalLine.TestField("wan Ending Date");
        end;
        if (GenJournalLine."wan Starting Date" = 0D) and (GenJournalLine."wan Ending Date" <> 0D) then
            GenJournalLine.FieldError("wan Ending Date", StrSubstNo(BothOrNoneErr, GenJournalLine.FieldCaption("wan Starting Date")));
        if (GenJournalLine."wan Starting Date" <> 0D) and (GenJournalLine."wan Ending Date" = 0D) then
            GenJournalLine.FieldError("wan Starting Date", StrSubstNo(BothOrNoneErr, GenJournalLine.FieldCaption("wan Ending Date")));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertGLEntry', '', false, false)]
    local procedure OnAfterInsertGLEntry(GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; TempGLEntryBuf: Record "G/L Entry" temporary; CalcAddCurrResiduals: Boolean)
    var
        PrepaidLedgerEntry: Record "wan Prepaid Ledger Entry";
    begin
        if GenJnlLine."wan Prepaid Entry No." <> 0 then begin
            PrepaidLedgerEntry.TransferFields(GLEntry, true);
            PrepaidLedgerEntry."Prepaid G/L Entry No." := GenJnlLine."wan Prepaid Entry No.";
            PrepaidLedgerEntry.Amount *= -1;
            PrepaidLedgerEntry.Insert(true);
        end else
            if (GLEntry."Gen. Posting Type" in [GLEntry."Gen. Posting Type"::Purchase, GLEntry."Gen. Posting Type"::Sale]) and
                (GenJnlLine."wan Starting Date" > GLEntry."Posting Date") then begin
                PrepaidLedgerEntry.TransferFields(GLEntry, true);
                PrepaidLedgerEntry."Prepaid G/L Entry No." := GLEntry."Entry No.";
                PrepaidLedgerEntry."Starting Date" := GenJnlLine."wan Starting Date";
                PrepaidLedgerEntry."Ending Date" := GenJnlLine."wan Ending Date";
                PrepaidLedgerEntry.Insert(true);
            end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnBeforeDeleteEvent', '', true, true)]
    local procedure OnBeforeDeleteGLEntry(Rec: Record "G/L Entry")
    var
        PrepaidLedgerEntry: Record "wan Prepaid Ledger Entry";
        IsNotNullErr: Label 'prepaid outstanding amount is not null';
    begin
        /* Warning
            Call stack : 
                codeunit "Gen. Jnl.-Post Line" ContinuePosting : TempGLEntryBuf.DeleteAll();
                where TemGLEntryBuf is temporary by passed by value to OnBeforeDeleteGLEntry...
                Can't be skipped if IsTemporary
        if Rec.IsTemporary then
            exit;
        if not PrepaidLedgerEntry.Get(Rec."Entry No.") then
            exit;
        if PrepaidLedgerEntry."Prepaid G/L Entry No." <> PrepaidLedgerEntry."G/L Entry No." then
            PrepaidLedgerEntry.FieldError("Prepaid G/L Entry No.", IsNotNullErr)
        else
            if PrepaidLedgerEntry.OutstandingAmount() <> 0 then
                PrepaidLedgerEntry.FieldError(Amount, IsNotNullErr);
        */
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", 'OnAfterDeleteEvent', '', true, true)]
    local procedure OnAfterDeleteGLEntry(Rec: Record "G/L Entry")
    var
        PrepaidLedgerEntry: Record "wan Prepaid Ledger Entry";
    begin
        /* Warning
            Call stack : 
                codeunit "Gen. Jnl.-Post Line" ContinuePosting : TempGLEntryBuf.DeleteAll();
                where TemGLEntryBuf is temporary by passed by value to OnBeforeDeleteGLEntry...
                Can't be skipped if IsTemporary
        if Rec.IsTemporary then
            exit;
        PrepaidLedgerEntry.SetCurrentKey("Prepaid G/L Entry No.");
        PrepaidLedgerEntry.SetRange("Prepaid G/L Entry No.", Rec."Entry No.");
        PrepaidLedgerEntry.DeleteAll(true);
        */
    end;
}
