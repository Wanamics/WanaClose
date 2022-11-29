report 87210 "wan Purch. Rcpt. not Inv."
{
    Caption = 'Suggest Purch. Rcpt. not Invoiced';
    ProcessingOnly = true;
    dataset
    {
        dataitem(PurchRcptLine; "Purch. Rcpt. Line")
        {
            RequestFilterFields = "Document No.", "Buy-from Vendor No.", "Order No.";
            DataItemTableView =
                sorting("Order No.", "Order Line No.", "Posting Date")
                where("Qty. Rcd. Not Invoiced" = filter('<>0'));
            trigger OnPreDataItem()
            begin
                Initialize();

                SetLoadFields("Order No.", "Order Line No.", "Posting Date", "Qty. Rcd. Not Invoiced");
                SetRange("Posting Date", 0D, TempGenJournalLine."Posting Date");
                PurchaseLine.SetLoadFields(
                    "Buy-from Vendor No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit Cost (LCY)",
                    "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Job No.", "Job Task No.");
            end;

            trigger OnAfterGetRecord()
            var
                AmountRcptNotInvLCY: Decimal;
            begin
                if ("Posting Group" = '') or (Type <> Type::Item) or not InventorySetup."Expected Cost Posting to G/L" then begin
                    if xPurchRcptLine."Document No." = '' then
                        xPurchRcptLine := PurchRcptLine;
                    if (OrderChange() or AllocationChange()) and (SumAmountRcptNotInvLCY <> 0) then begin
                        if xPurchRcptLine."Order No." <> GenJournalLine."External Document No." then begin
                            UpdateGenJournalLineAmount();
                            InsertGenJournalLine();
                            TempGenJournalLine."Document Date" := 0D;
                        end;
                        InsertGenJnlAllocation();
                    end;
                    if ("Order No." <> PurchaseLine."Document No.") or ("Order Line No." <> PurchaseLine."Line No.") then
                        PurchaseLine.Get(PurchaseLine."Document Type"::Order, "Order No.", "Order Line No.");
                    AmountRcptNotInvLCY := Round("Qty. Rcd. Not Invoiced" * PurchaseLine."Unit Cost (LCY)");
                    SumAmountRcptNotInvLCY += AmountRcptNotInvLCY;
                    SumVAT += Round(AmountRcptNotInvLCY * PurchRcptLine."VAT %" / 100);
                    if "Posting Date" < TempGenJournalLine."Document Date" then
                        TempGenJournalLine."Document Date" := "Posting Date";
                    xPurchRcptLine := PurchRcptLine;
                end;
            end;

            trigger OnPostDataItem()
            var
                GLAccount: Record "G/L Account";
            begin
                if SumAmountRcptNotInvLCY <> 0 then
                    InsertGenJnlAllocation();
                UpdateGenJournalLineAmount();

                TempGenJournalLine."Line No." += 10000;
                GenJournalLine.TransferFields(TempGenJournalLine, true);
                GLAccount.Get(ReceiptNotInvVATAccountNo);
                GenJournalLine.Description := GLAccount.Name;
                GenJournalLine.Validate(Amount, -SumVAT);
                GenJournalLine.Insert(true);

                GenJnlAllocation.Init();
                GenJnlAllocation."Journal Line No." := GenJournalLine."Line No.";
                GenJnlAllocation."Line No." := 10000;
                GenJnlAllocation.Insert(true);
                GenJnlAllocation.Validate("Account No.", ReceiptNotInvVATAccountNo);
                GenJnlAllocation.Validate(Amount, -GenJournalLine.Amount);
                GenJnlAllocation.Modify(true);
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
                    /*
                    field(DocumentNo; DocumentNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Document No.', FRA = 'N° document';
                    }
                    */
                    field(ReceiptNotInvAccountNo; ReceiptNotInvAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Receipt not Inv. Account No.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        ToolTip = 'Account root 408 on a french chart of account.';
                    }
                    field(ReceiptNotInvVATAccountNo; ReceiptNotInvVATAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Receipt not Inv. VAT Account No.';
                        ToolTip = 'Account root 44586 on a french chart of account.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                    }
                }
            }
        }
        actions
        {
            area(processing)
            {
            }
        }
    }
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        PostingDate: Date;
        //DocumentNo: Code[20];
        ReceiptNotInvAccountNo: Code[20];
        ReceiptNotInvVATAccountNo: Code[20];
        InventorySetup: Record "Inventory Setup";
        GenJournalLine: Record "Gen. Journal Line";
        xPurchRcptLine: Record "Purch. Rcpt. Line";
        PurchaseLine: Record "Purchase Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        SumAmountRcptNotInvLCY: Decimal;
        SumVAT: Decimal;
        GLAccount: Record "G/L Account";
        InventoryPostingSetup: Record "Inventory Posting Setup";

    trigger OnPreReport()
    var
        ErrorMsg: Label 'All parameter are required';
        ConfirmQst: Label 'Do you want to suggest not Amt. Rcd. Not Invoiced on %1?';
        WarningMsg: Label 'Warning : This process should not be posted twice at the same posting date for the same selection!';
    begin
        if (PostingDate = 0D) /*or (DocumentNo = '') */or (ReceiptNotInvAccountNo = '') or (ReceiptNotInvVATAccountNo = '') then
            Error(ErrorMsg);
        if not Confirm(ConfirmQst + '\\' + WarningMsg, false, PostingDate) then
            CurrReport.Quit();
        InventorySetup.Get();
    end;

    procedure SetInitGenJournalLine(pGenJournalLine: Record "Gen. Journal Line")
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
        TempGenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"RV Reversing Variable");
        Evaluate(TempGenJournalLine."Recurring Frequency", '<1D>');
        TempGenJournalLine.Validate("Recurring Frequency");
        TempGenJournalLine.Validate("Expiration Date", PostingDate + 1);
    end;

    local procedure Initialize()
    var
        tDocumentNo: Label 'RnI';
    begin
        TempGenJournalLine.Validate("Posting Date", PostingDate);
        TempGenJournalLine.Validate("Document No.", tDocumentNo);
        TempGenJournalLine.Validate("Expiration Date", PostingDate);
        TempGenJournalLine.Validate("Account No.", ReceiptNotInvAccountNo);

        GenJnlAllocation."Journal Template Name" := TempGenJournalLine."Journal Template Name";
        GenJnlAllocation."Journal Batch Name" := TempGenJournalLine."Journal Batch Name";
    end;

    local procedure OrderChange() ReturnValue: Boolean
    begin
        ReturnValue := PurchRcptLine."Order No." <> xPurchRcptLine."Order No.";
    end;

    local procedure AllocationChange(): Boolean
    var
        xInventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if PurchRcptLine.Type = PurchRcptLine.Type::Item then begin
            xInventoryPostingSetup := InventoryPostingSetup;
            if ((PurchRcptLine."Posting Group" <> InventoryPostingSetup."Invt. Posting Group Code") or
                 (PurchRcptLine."Location Code" <> InventoryPostingSetup."Location Code")) then
                InventoryPostingSetup.Get(PurchRcptLine."Location Code", PurchRcptLine."Posting Group");
            exit(InventoryPostingSetup."Inventory Account" <> xInventoryPostingSetup."Inventory Account");
        end else
            exit(
                (PurchRcptLine."Dimension Set ID" <> xPurchRcptLine."Dimension Set ID") or
                (PurchRcptLine."Gen. Bus. Posting Group" <> xPurchRcptLine."Gen. Bus. Posting Group") or
                (PurchRcptLine."Gen. Prod. Posting Group" <> xPurchRcptLine."Gen. Prod. Posting Group"));
    end;

    local procedure InsertGenJournalLine()
    var
        RcdNotInv: Label 'RnI %1 %2';
    begin
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GenJournalLine."External Document No." := xPurchRcptLine."Order No.";
        if xPurchRcptLine."Buy-from Vendor No." <> Vendor."No." then
            Vendor.Get(xPurchRcptLine."Buy-from Vendor No.");
        GenJournalLine.Description := CopyStr(Strsubstno(RcdNotInv, xPurchRcptLine."Order No.", Vendor.Name), 1, maxstrlen(GenJournalLine.Description));
        GenJournalLine."IC Partner Code" := Vendor."IC Partner Code"; //#20221030
        GenJournalLine.Insert(true);
    end;

    local procedure InsertGenJnlAllocation()
    begin
        GenJnlAllocation.Init();
        GenJnlAllocation."Journal Line No." := GenJournalLine."Line No.";
        GenJnlAllocation."Line No." += 10000;
        if xPurchRcptLine.Type = xPurchRcptLine.Type::Item then
            GenJnlAllocation.Validate("Account No.", InventoryPostingSetup."Inventory Account")
        else begin
            if (xPurchRcptLine."Gen. Bus. Posting Group" <> GeneralPostingSetup."Gen. Bus. Posting Group") or
               (xPurchRcptLine."Gen. Prod. Posting Group" <> GeneralPostingSetup."Gen. Prod. Posting Group") then begin
                GeneralPostingSetup.Get(xPurchRcptLine."Gen. Bus. Posting Group", xPurchRcptLine."Gen. Prod. Posting Group");
                if GeneralPostingSetup."Purch. Account" <> GLAccount."No." then begin
                    GLAccount.Get(GeneralPostingSetup."Purch. Account");
                    GLAccount.TestField("Direct Posting", true);
                end;
            end;
            GenJnlAllocation.Validate("Account No.", GeneralPostingSetup."Purch. Account");
        end;
        if xPurchRcptLine.Type <> xPurchRcptLine.Type::Item then begin
            GenJnlAllocation."Shortcut Dimension 1 Code" := xPurchRcptLine."Shortcut Dimension 1 Code";
            GenJnlAllocation."Shortcut Dimension 2 Code" := xPurchRcptLine."Shortcut Dimension 2 Code";
            GenJnlAllocation."Dimension Set ID" := xPurchRcptLine."Dimension Set ID";
        end;
        GenJnlAllocation.Insert(true);
        GenJnlAllocation.Validate(Amount, SumAmountRcptNotInvLCY);
        GenJnlAllocation.Modify(true);

        GenJournalLine.Amount -= SumAmountRcptNotInvLCY;
        SumAmountRcptNotInvLCY := 0;
    end;

    local procedure UpdateGenJournalLineAmount()
    begin
        if GenJournalLine.Amount <> 0 then begin
            GenJournalLine.Validate(Amount);
            GenJournalLine.Modify(true);
        end;
    end;
}
