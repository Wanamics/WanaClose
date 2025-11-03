codeunit 87250 "wan Deferral Events"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Check Line", OnAfterCheckGenJnlLine, '', false, false)]
    local procedure OnAfterCheckGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; var ErrorMessageMgt: Codeunit "Error Message Management")
    var
        InseparableErr: Label 'and %1 are unseparable';
        GLAccount: Record "G/L Account";
        DeferralTemplate: Record "Deferral Template";
    begin
        if GenJournalLine."Account Type" <> GenJournalLine."Account Type"::"G/L Account" then
            exit;
        if not (GenJournalLine."Gen. Posting Type" in [GenJournalLine."Gen. Posting Type"::Purchase, GenJournalLine."Gen. Posting Type"::Sale]) then
            exit;
        if GenJournalLine."Deferral Code" <> '' then
            if DeferralTemplate.Get(GenJournalLine."Deferral Code") and (DeferralTemplate."No. of Periods" = 0) then begin
                GenJournalLine.TestField("wan Deferral Starting Date");
                GenJournalLine.TestField("wan Deferral Ending Date");
            end else begin
                GenJournalLine.TestField("wan Deferral Starting Date", 0D);
                GenJournalLine.TestField("wan Deferral Ending Date", 0D);
            end;
        if (GenJournalLine."wan Deferral Starting Date" = 0D) and (GenJournalLine."wan Deferral Ending Date" <> 0D) then
            GenJournalLine.FieldError("wan Deferral Ending Date", StrSubstNo(InseparableErr, GenJournalLine.FieldCaption("wan Deferral Starting Date")));
        if (GenJournalLine."wan Deferral Starting Date" <> 0D) and (GenJournalLine."wan Deferral Ending Date" = 0D) then
            GenJournalLine.FieldError("wan Deferral Starting Date", StrSubstNo(InseparableErr, GenJournalLine.FieldCaption("wan Deferral Ending Date")));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnPostGLAccOnBeforeInsertGLEntry, '', false, false)]
    local procedure OnPostGLAccOnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; var GLEntry: Record "G/L Entry"; var IsHandled: Boolean; Balancing: Boolean)
    begin
        if Balancing then
            GenJournalLine."wan Deferral Entry No." := 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnAfterInsertGLEntry, '', false, false)]
    local procedure OnAfterInsertGLEntry(GLEntry: Record "G/L Entry"; GenJnlLine: Record "Gen. Journal Line"; TempGLEntryBuf: Record "G/L Entry" temporary; CalcAddCurrResiduals: Boolean)
    var
        DeferralLedgerEntry: Record "wan Deferral Ledger Entry";
    begin
        if GenJnlLine."wan Deferral Entry No." <> 0 then begin
            DeferralLedgerEntry.TransferFields(GLEntry, true);
            DeferralLedgerEntry."Deferral G/L Entry No." := GenJnlLine."wan Deferral Entry No.";
            DeferralLedgerEntry.Amount *= -1;
            DeferralLedgerEntry.Insert(true);
        end else
            if GLEntry."Reversed Entry No." <> 0 then begin
                if DeferralLedgerEntry.Get(GLEntry."Reversed Entry No.") then begin
                    DeferralLedgerEntry."G/L Entry No." := GLEntry."Entry No.";
                    DeferralLedgerEntry."Gen. Posting Type" := DeferralLedgerEntry."Gen. Posting Type"::" ";
                    DeferralLedgerEntry.Insert(true);
                end
            end else
                if (GLEntry."Gen. Posting Type" in [GLEntry."Gen. Posting Type"::Purchase, GLEntry."Gen. Posting Type"::Sale]) and
                    (GenJnlLine."wan Deferral Ending Date" <> 0D) then begin
                    DeferralLedgerEntry.TransferFields(GLEntry, true);
                    DeferralLedgerEntry."Deferral G/L Entry No." := GLEntry."Entry No.";
                    DeferralLedgerEntry."Starting Date" := GenJnlLine."wan Deferral Starting Date";
                    DeferralLedgerEntry."Ending Date" := GenJnlLine."wan Deferral Ending Date";
                    DeferralLedgerEntry.Insert(true);
                end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnBeforeDeleteEvent, '', true, true)]
    local procedure OnBeforeDeleteGLEntry(Rec: Record "G/L Entry")
    var
        DeferralLedgerEntry: Record "wan Deferral Ledger Entry";
        IsNotNullErr: Label 'Deferral outstanding amount is not null';
    begin
        /* Warning
            Call stack : 
                codeunit "Gen. Jnl.-Post Line" ContinuePosting : TempGLEntryBuf.DeleteAll();
                where TemGLEntryBuf is temporary by passed by value to OnBeforeDeleteGLEntry...
                Can't be skipped if IsTemporary
        if Rec.IsTemporary then
            exit;
        if not DeferralLedgerEntry.Get(Rec."Entry No.") then
            exit;
        if DeferralLedgerEntry."Deferral G/L Entry No." <> DeferralLedgerEntry."G/L Entry No." then
            DeferralLedgerEntry.FieldError("Deferral G/L Entry No.", IsNotNullErr)
        else
            if DeferralLedgerEntry.OutstandingAmount() <> 0 then
                DeferralLedgerEntry.FieldError(Amount, IsNotNullErr);
        */
    end;

    [EventSubscriber(ObjectType::Table, Database::"G/L Entry", OnAfterDeleteEvent, '', true, true)]
    local procedure OnAfterDeleteGLEntry(Rec: Record "G/L Entry")
    var
        DeferralLedgerEntry: Record "wan Deferral Ledger Entry";
    begin
        /* Warning
            Call stack : 
                codeunit "Gen. Jnl.-Post Line" ContinuePosting : TempGLEntryBuf.DeleteAll();
                where TemGLEntryBuf is temporary by passed by value to OnBeforeDeleteGLEntry...
                Can't be skipped if IsTemporary
        if Rec.IsTemporary then
            exit;
        DeferralLedgerEntry.SetCurrentKey("Deferral G/L Entry No.");
        DeferralLedgerEntry.SetRange("Deferral G/L Entry No.", Rec."Entry No.");
        DeferralLedgerEntry.DeleteAll(true);
        */
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Deferral Utilities", OnBeforeValidateDeferralTemplate, '', false, false)]
    local procedure OnBeforeValidateDeferralTemplate(DeferralTemplate: Record "Deferral Template"; var IsHandled: Boolean)
    begin
        if DeferralTemplate."No. of Periods" = 0 then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforePostDeferralPostBuffer, '', false, false)]
    local procedure OnBeforePostDeferralPostBuffer(var GenJournalLine: Record "Gen. Journal Line"; var IsHandled: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        if GenJournalLine."Deferral Code" = '' then
            exit;
        if DeferralTemplate.Get(GenJournalLine."Deferral Code") then
            IsHandled := (DeferralTemplate."No. of Periods" = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", OnBeforeDeferralPosting, '', false, false)]
    local procedure OnBeforeDeferralPosting(DeferralCode: Code[10]; SourceCode: Code[10]; var AccountNo: Code[20]; var GenJournalLine: Record "Gen. Journal Line"; Balancing: Boolean; var IsHandled: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        if DeferralCode = '' then
            exit;
        if DeferralTemplate.Get(DeferralCode) then
            IsHandled := (DeferralTemplate."No. of Periods" = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Deferral Utilities", OnBeforeCreateDeferralSchedule, '', false, false)]
    local procedure OnBeforeCreateDeferralSchedule(DeferralCode: Code[10]; DeferralDocType: Integer; GenJnlTemplateName: Code[10]; GenJnlBatchName: Code[10]; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; AmountToDefer: Decimal; CalcMethod: Enum "Deferral Calculation Method"; var StartDate: Date; var NoOfPeriods: Integer; ApplyDeferralPercentage: Boolean; DeferralDescription: Text[100]; var AdjustStartDate: Boolean; CurrencyCode: Code[10]; var IsHandled: Boolean; var RedistributeDeferralSchedule: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        IsHandled := DeferralTemplate.Get(DeferralCode) and (DeferralTemplate."No. of Periods" = 0);
    end;
}