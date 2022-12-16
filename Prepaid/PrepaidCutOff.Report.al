report 87220 "wan Suggest Prepaid Entries"
{
    Caption = 'Suggest Prepaid Expenses & Deferred Revenue';
    ProcessingOnly = true;
    dataset
    {
        dataitem(PrepaidLedgerEntry; "wan Prepaid Ledger Entry")
        {
            CalcFields = Amount;

            DataItemTableView =
                sorting("Gen. Posting Type", "Posting Date", "IC Partner Code")
                where("Gen. Posting Type" = filter(Purchase | Sale));
            trigger OnAfterGetRecord()
            var
                GLEntry: Record "G/L Entry";
                ClosingAmount: Decimal;
            begin
                if ("Gen. Posting Type" <> xPrepaidLedgerEntry."Gen. Posting Type") or
                    ("IC Partner Code" <> xPrepaidLedgerEntry."IC Partner Code") then
                    InsertBalance(xPrepaidLedgerEntry."Gen. Posting Type", BalanceAmount);
                ClosingAmount := AccruedAmount(PrepaidLedgerEntry, TempGenJournalLine."Posting Date");
                if ClosingAmount <> 0 then
                    InsertGenJournalLine(PrepaidLedgerEntry."G/L Entry No.", ClosingAmount);
                BalanceAmount -= ClosingAmount;
                xPrepaidLedgerEntry := PrepaidLedgerEntry;
            end;

            trigger OnPostDataItem()
            begin
                InsertBalance(xPrepaidLedgerEntry."Gen. Posting Type", BalanceAmount);
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
                    field(PrepaidExpensesAccountNo; PrepaidExpensesAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Prepaid Expenses Account No.';
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
        PrepaidExpensesAccountNo: Code[20];
        DeferredRevenueAccountNo: Code[20];
        BalanceAmount: Decimal;
        xPrepaidLedgerEntry: Record "wan Prepaid Ledger Entry";

    trigger OnPreReport()
    var
        ErrorMsg: Label 'All parameter are required';
        ConfirmQst: Label 'Do you want to suggest prepaid expenses and Deferred Revenue to %1?';
        AccountingPeriod: Record "Accounting Period";
        AccountingPeriodErr: Label 'Posting Date must match the end of an accounting period';
    begin
        if (TempGenJournalLine."Posting Date" = 0D) or (TempGenJournalLine."Document No." = '') or
            (PrepaidExpensesAccountNo = '') or (DeferredRevenueAccountNo = '') then
            Error(ErrorMsg);
        AccountingPeriod.SetRange("Starting Date", PostingDate + 1);
        if AccountingPeriod.IsEmpty then
            Error(AccountingPeriodErr);
        if not Confirm(ConfirmQst, false, PostingDate) then
            CurrReport.Quit();
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

    local procedure InsertGenJournalLine(pGLEntryNo: Integer; pClosingAmount: Decimal)
    var
        GLEntry: Record "G/L Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PrepaidExpensesDescription: Label 'PE %1';
        DeferredRevenueDescription: Label 'DR %1';
    begin
        GLEntry.Get(pGLEntryNo);
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GenJournalLine.Validate("Account No.", GLEntry."G/L Account No.");
        GenJournalLine.Validate(Amount, pClosingAmount);
        case GLEntry."Gen. Posting Type" of
            GLEntry."Gen. Posting Type"::Purchase:
                GenJournalLine.Description := CopyStr(Strsubstno(PrepaidExpensesDescription, GLEntry.Description), 1, maxstrlen(GenJournalLine.Description));
            GLEntry."Gen. Posting Type"::Sale:
                GenJournalLine.Description := CopyStr(Strsubstno(DeferredRevenueDescription, GLEntry.Description), 1, maxstrlen(GenJournalLine.Description));
        end;
        GenJournalLine."Shortcut Dimension 1 Code" := GLEntry."Global Dimension 1 Code";
        GenJournalLine."Shortcut Dimension 2 Code" := GLEntry."Global Dimension 2 Code";
        GenJournalLine."Dimension Set ID" := GLEntry."Dimension Set ID";
        GenJournalLine.Validate("IC Partner Code", GLEntry."IC Partner Code");
        GenJournalLine."wan Prepaid Entry No." := GLEntry."Entry No.";
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
                GenJournalLine.Validate("Account No.", PrepaidExpensesAccountNo);
            pGeneralPostingType::Sale:
                GenJournalLine.Validate("Account No.", DeferredRevenueAccountNo);
        end;
        GenJournalLine.Validate(Amount, pBalanceAmount);
        GenJournalLine.Insert(true);
        pBalanceAmount := 0;
    end;


    local procedure AccruedAmount(pPrepaidLedgerEntry: Record "wan Prepaid Ledger Entry"; pPostingDate: Date): Decimal
    var
    begin
        if (pPrepaidLedgerEntry."Starting Date" > pPostingDate) or
            (pPrepaidLedgerEntry."Ending Date" <= pPostingDate) then
            exit(PrepaidLedgerEntry.Amount - pPrepaidLedgerEntry.OutstandingAmount());
        // TODO Fixed Amount per period
        exit(
            Round(
                pPrepaidLedgerEntry.Amount /
                (pPrepaidLedgerEntry."Ending Date" - pPrepaidLedgerEntry."Starting Date" + 1) *
                (pPostingDate - pPrepaidLedgerEntry."Starting Date" + 1)
                )
            - PrepaidLedgerEntry.Amount
            );
    end;
}
