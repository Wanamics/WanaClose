report 87220 "wan Suggest Deferral Entries"
{
    Caption = 'Suggest Deferral Expenses & Deferred Revenue';
    ProcessingOnly = true;
    dataset
    {
        dataitem(DeferralLedgerEntry; "wan Deferral Ledger Entry")
        {
            CalcFields = Amount;

            DataItemTableView =
                sorting("Gen. Posting Type", "Posting Date", "IC Partner Code")
                where("Gen. Posting Type" = filter(Purchase | Sale));
            trigger OnAfterGetRecord()
            var
                //ClosingAmount: Decimal;
                GLEntry: Record "G/L Entry";
            begin
                if ("Gen. Posting Type" <> xDeferralLedgerEntry."Gen. Posting Type") or
                    ("IC Partner Code" <> xDeferralLedgerEntry."IC Partner Code") then
                    InsertBalance(xDeferralLedgerEntry."Gen. Posting Type", BalanceAmount);
                /*
                ClosingAmount := TargetAmount(DeferralLedgerEntry, TempGenJournalLine."Posting Date") - DeferralLedgerEntry.OutstandingAmount(TempGenJournalLine."Posting Date");
                if ClosingAmount <> 0 then begin
                    GLEntry.Get(DeferralLedgerEntry."G/L Entry No.");
                    if GLEntry.Reversed then //?????????????
                        InsertGenJournalLine(GLEntry, -DeferralLedgerEntry.OutstandingAmount(TempGenJournalLine."Posting Date"))
                    else
                        InsertGenJournalLine(GLEntry, ClosingAmount);
                */
                GLEntry.Get(DeferralLedgerEntry."G/L Entry No.");
                if GLEntry.Reversed then
                    InsertGenJournalLine(GLEntry, -DeferralLedgerEntry.OutstandingAmount(TempGenJournalLine."Posting Date"))
                else
                    InsertGenJournalLine(GLEntry, TargetAmount(DeferralLedgerEntry, TempGenJournalLine."Posting Date") - DeferralLedgerEntry.OutstandingAmount(TempGenJournalLine."Posting Date"));
                xDeferralLedgerEntry := DeferralLedgerEntry;
            end;

            trigger OnPostDataItem()
            begin
                InsertBalance(xDeferralLedgerEntry."Gen. Posting Type", BalanceAmount);
            end;
        }
    }
    requestpage
    {
        SaveValues = true;
        layout
        {
            area(content)
            {
                group(Options)
                {
                    field(PostingDate; PostingDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Posting Date';
                    }
                    field(DocumentNo; TempGenJournalLine."Document No.")
                    {
                        ApplicationArea = All;
                        Caption = 'Document No.';
                    }
                    field(DeferralExpensesAccountNo; DeferralExpensesAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Deferral Expenses Account No.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        ToolTip = 'Account root 486 on a french chart of account.';
                    }
                    field(DeferredRevenueAccountNo; DeferredRevenueAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Deferred Revenue Account No.';
                        ToolTip = 'Account root 487 on a french chart of account.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                    }
                }
            }
        }
    }
    var
        PostingDate: Date;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        DeferralExpensesAccountNo: Code[20];
        DeferredRevenueAccountNo: Code[20];
        BalanceAmount: Decimal;
        xDeferralLedgerEntry: Record "wan Deferral Ledger Entry";

    trigger OnPreReport()
    var
        ErrorMsg: Label 'All parameter are required';
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriodErr: Label 'Posting Date must match the end of an accounting period';
    begin
        if (TempGenJournalLine."Posting Date" = 0D) or (TempGenJournalLine."Document No." = '') or
            (DeferralExpensesAccountNo = '') or (DeferredRevenueAccountNo = '') then
            Error(ErrorMsg);
        AccountingPeriod.SetRange("Starting Date", PostingDate + 1);
        if AccountingPeriod.IsEmpty then
            Error(AccountingPeriodErr);
        TempGenJournalLine.Validate("Posting Date", PostingDate);
        TempGenJournalLine.Validate("Document No.");
    end;

    procedure SetGenJournalLine(pGenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        lRec: Record "Gen. Journal Line";
        JournalMustBeEmpty: Label 'Journal must be empty';
    begin
        lRec.SetRange("Journal Template Name", pGenJournalLine."Journal Template Name");
        lRec.SetRange("Journal Batch Name", pGenJournalLine."Journal Batch Name");
        if not lRec.IsEmpty then
            Error(JournalMustBeEmpty);
        pGenJournalLine.TestField("Source Code");
        GenJournalBatch.Get(pGenJournalLine."Journal Template Name", pGenJournalLine."Journal Batch Name");
        GenJournalBatch.TestField("Copy VAT Setup to Jnl. Lines", false);

        TempGenJournalLine := pGenJournalLine;
        TempGenJournalLine.SetUpNewLine(pGenJournalLine, 0, true);
    end;

    local procedure InsertGenJournalLine(pGLEntry: Record "G/L Entry"; pAmount: Decimal)
    var
        //pGLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        DeferralExpensesDescription: Label 'PE %1 %2';
        DeferredRevenueDescription: Label 'DR %1 %2';
    begin
        //GLEntry.Get(pGLEntryNo);
        if pAmount = 0 then
            exit;
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GenJournalLine.Validate("Account No.", pGLEntry."G/L Account No.");
        GenJournalLine.Validate(Amount, pAmount);
        case pGLEntry."Gen. Posting Type" of
            pGLEntry."Gen. Posting Type"::Purchase:
                GenJournalLine.Description := CopyStr(Strsubstno(DeferralExpensesDescription, pGLEntry."Document No.", pGLEntry.Description), 1, maxstrlen(GenJournalLine.Description));
            pGLEntry."Gen. Posting Type"::Sale:
                GenJournalLine.Description := CopyStr(Strsubstno(DeferredRevenueDescription, pGLEntry."Document No.", pGLEntry.Description), 1, maxstrlen(GenJournalLine.Description));
        end;
        GenJournalLine."Shortcut Dimension 1 Code" := pGLEntry."Global Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := pGLEntry."Global Dimension 2 Code";
        GenJournalLine."Dimension Set ID" := pGLEntry."Dimension Set ID";
        GenJournalLine.Validate("IC Partner Code", pGLEntry."IC Partner Code");
        GenJournalLine."wan Deferral Entry No." := pGLEntry."Entry No.";
        if pGLEntry."IC Partner Code" = '' then
            BalanceAmount -= pAmount
        else begin
            GenJournalLine.Validate("IC Partner Code", pGLEntry."IC Partner Code");
            if pGLEntry."Gen. Posting Type" = pGLEntry."Gen. Posting Type"::Purchase then
                GenJournalLine.Validate("Bal. Account No.", DeferralExpensesAccountNo)
            else
                GenJournalLine.Validate("Bal. Account No.", DeferredRevenueAccountNo);
        end;
        GenJournalLine.Insert(true);
    end;

    local procedure InsertBalance(pGeneralPostingType: Enum "General Posting Type"; var pBalanceAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        if pBalanceAmount = 0 then
            exit;
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        case pGeneralPostingType of
            pGeneralPostingType::Purchase:
                GenJournalLine.Validate("Account No.", DeferralExpensesAccountNo);
            pGeneralPostingType::Sale:
                GenJournalLine.Validate("Account No.", DeferredRevenueAccountNo);
        end;
        GenJournalLine.Validate(Amount, pBalanceAmount);
        GenJournalLine.Insert(true);
        pBalanceAmount := 0;
    end;

    local procedure TargetAmount(pDeferralLedgerEntry: Record "wan Deferral Ledger Entry"; pPostingDate: Date): Decimal
    var
        Month: Record Date;
        FirstMonthAmount: Decimal;
        PerMonthAmount: Decimal;
    begin
        if pPostingDate < pDeferralLedgerEntry."Starting Date" then
            exit(0);
        if pPostingDate < pDeferralLedgerEntry."Posting Date" then
            exit(0);
        if pDeferralLedgerEntry."Ending Date" <= pPostingDate then
            exit(pDeferralLedgerEntry.Amount);

        Month.SetRange("Period Type", Month."Period Type"::Month);
        Month.SetRange("Period Start", pDeferralLedgerEntry."Starting Date", pDeferralLedgerEntry."Ending Date");
        Month.FindFirst();
        if pPostingDate < Month."Period Start" then
            exit(ProrataTemporis(pDeferralLedgerEntry, pPostingDate));
        if pDeferralLedgerEntry."Starting Date" <> Month."Period Start" then
            FirstMonthAmount := ProrataTemporis(pDeferralLedgerEntry, Month."Period Start" - 1);
        if (Date2DMY(pDeferralLedgerEntry."Ending Date", 1) = Date2DMY(pDeferralLedgerEntry."Starting Date", 1) - 1) or
            (pDeferralLedgerEntry."Starting Date" = CalcDate('<-CM>', pDeferralLedgerEntry."Starting Date")) and
                (pDeferralLedgerEntry."Ending Date" = CalcDate('<+CM>', pDeferralLedgerEntry."Ending Date")) then
            PerMonthAmount := Round(pDeferralLedgerEntry.Amount / Month.Count)
        else
            PerMonthAmount := Round(pDeferralLedgerEntry.Amount / (pDeferralLedgerEntry."Ending Date" - pDeferralLedgerEntry."Starting Date" + 1) * 30);
        Month.SetRange("Period Start", pDeferralLedgerEntry."Starting Date", pPostingDate);
        exit(FirstMonthAmount + PerMonthAmount * Month.Count);
    end;

    local procedure ProrataTemporis(pDeferralLedgerEntry: Record "wan Deferral Ledger Entry"; pDate: Date): Decimal
    begin
        exit(Round(
            DeferralLedgerEntry.Amount /
            (DeferralLedgerEntry."Ending Date" - pDeferralLedgerEntry."Starting Date" + 1) *
            (pDate - pDeferralLedgerEntry."Starting Date" + 1)));
    end;
}