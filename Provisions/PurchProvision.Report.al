report 87210 "wan Suggest Purch. Provisions"
{
    Caption = 'Suggest Purchase Provisions';
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
            var
                DocumentNo: Label 'ExpInv';
                ProvisionDescription: Label 'Exp.Inv. %1 %2';
            begin
                SumProvisionAmount := 0;
                SumVATAmount := 0;
                TempGenJournalLine."Document No." := DocumentNo;
                TempGenJournalLine.Description := ProvisionDescription;
                SetLoadFields("Order No.", "Order Line No.", "Posting Date", "Qty. Rcd. Not Invoiced");
                SetRange("Posting Date", 0D, TempGenJournalLine."Posting Date");
                PurchaseLine.SetLoadFields(
                    "Buy-from Vendor No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit Cost (LCY)",
                    "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Job No.", "Job Task No.");
            end;

            trigger OnAfterGetRecord()
            var
                ProvisionAmount: Decimal;
            begin
                if ("Posting Group" = '') or (Type <> Type::Item) or not ExpectedCostPostingToGL then begin
                    if xPRL."Document No." = '' then
                        xPRL := PurchRcptLine;
                    if (OrderChange() or PurchRcptLineAllocationChange()) and (SumProvisionAmount <> 0) then begin
                        if xPRL."Order No." <> GenJournalLine."External Document No." then begin
                            UpdateGenJournalLineAmount();
                            InsertGenJournalLine(xPRL."Buy-from Vendor No.", xPRL."Order No.");
                            TempGenJournalLine."Document Date" := 0D;
                        end;
                        InsertGenJnlAllocation(
                            xPRL.Type, xPRL."Gen. Bus. Posting Group", xPRL."Gen. Prod. Posting Group",
                            xPRL."Shortcut Dimension 1 Code", xPRL."Shortcut Dimension 2 Code", xPRL."Dimension Set ID");
                    end;
                    if ("Order No." <> PurchaseLine."Document No.") or ("Order Line No." <> PurchaseLine."Line No.") then
                        PurchaseLine.Get(PurchaseLine."Document Type"::Order, "Order No.", "Order Line No.");
                    ProvisionAmount := Round("Qty. Rcd. Not Invoiced" * PurchaseLine."Unit Cost (LCY)");
                    SumProvisionAmount += ProvisionAmount;
                    SumVATAmount += Round(ProvisionAmount * PurchRcptLine."VAT %" / 100);
                    if "Posting Date" < TempGenJournalLine."Document Date" then
                        TempGenJournalLine."Document Date" := "Posting Date";
                    xPRL := PurchRcptLine;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if SumProvisionAmount <> 0 then begin
                    UpdateGenJournalLineAmount();
                    InsertGenJournalLine(xPRL."Buy-from Vendor No.", xPRL."Order No.");
                    TempGenJournalLine."Document Date" := 0D;
                end;
                InsertGenJnlAllocation(
                    xPRL.Type, xPRL."Gen. Bus. Posting Group", xPRL."Gen. Prod. Posting Group",
                    xPRL."Shortcut Dimension 1 Code", xPRL."Shortcut Dimension 2 Code", xPRL."Dimension Set ID");
                UpdateGenJournalLineAmount();
                InsertVATGenJournalLine(-SumVATAmount);
            end;
        }
        dataitem(ReturnShipmentLine; "Return Shipment Line")
        {
            RequestFilterFields = "Document No.", "Buy-from Vendor No.", "Return Order No.";
            DataItemTableView =
                sorting("Return Order No.", "Return Order Line No.")
                where("Return Qty. Shipped Not Invd." = filter('<>0'));
            trigger OnPreDataItem()
            var
                ProvisionDocumentNo: Label 'ExpCM';
                ProvisionDescription: Label 'Exp.CM %1 %2';
            begin
                SumProvisionAmount := 0;
                SumVATAmount := 0;
                TempGenJournalLine."Document No." := ProvisionDocumentNo;
                TempGenJournalLine."Description" := ProvisionDescription;
                SetLoadFields("Return Order No.", "Return Order Line No.", "Posting Date", "Return Qty. Shipped Not Invd.");
                SetRange("Posting Date", 0D, TempGenJournalLine."Posting Date");
                PurchaseLine.SetLoadFields(
                    "Buy-from Vendor No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit Cost (LCY)",
                    "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Job No.", "Job Task No.");
            end;

            trigger OnAfterGetRecord()
            var
                ProvisionAmount: Decimal;
            begin
                if ("Posting Group" = '') or (Type <> Type::Item) or not ExpectedCostPostingToGL then begin
                    if xRSL."Document No." = '' then
                        xRSL := ReturnShipmentLine;
                    if (ReturnOrderChange() or ReturnShipmentLineAllocationChange()) and (SumProvisionAmount <> 0) then begin
                        if xRSL."Return Order No." <> GenJournalLine."External Document No." then begin
                            UpdateGenJournalLineAmount();
                            InsertGenJournalLine(xRSL."Buy-from Vendor No.", xRSL."Return Order No.");
                            TempGenJournalLine."Document Date" := 0D;
                        end;
                        InsertGenJnlAllocation(
                            xRSL.Type, xRSL."Gen. Bus. Posting Group", xRSL."Gen. Prod. Posting Group",
                            xRSL."Shortcut Dimension 1 Code", xRSL."Shortcut Dimension 2 Code", xPRL."Dimension Set ID");
                    end;
                    if ("Return Order No." <> PurchaseLine."Document No.") or ("Return Order Line No." <> PurchaseLine."Line No.") then
                        PurchaseLine.Get(PurchaseLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.");
                    ProvisionAmount := Round("Return Qty. Shipped Not Invd." * PurchaseLine."Unit Cost (LCY)");
                    SumProvisionAmount += ProvisionAmount;
                    SumVATAmount += Round(ProvisionAmount * ReturnShipmentLine."VAT %" / 100);
                    if "Posting Date" < TempGenJournalLine."Document Date" then
                        TempGenJournalLine."Document Date" := "Posting Date";
                    xRSL := ReturnShipmentLine;
                end;
            end;

            trigger OnPostDataItem()
            var
                GLAccount: Record "G/L Account";
            begin
                if SumProvisionAmount <> 0 then begin
                    UpdateGenJournalLineAmount();
                    InsertGenJournalLine(xPRL."Buy-from Vendor No.", xPRL."Order No.");
                    TempGenJournalLine."Document Date" := 0D;
                end;
                InsertGenJnlAllocation(
                    xRSL.Type, xRSL."Gen. Bus. Posting Group", xRSL."Gen. Prod. Posting Group",
                    xRSL."Shortcut Dimension 1 Code", xRSL."Shortcut Dimension 2 Code", xPRL."Dimension Set ID");
                UpdateGenJournalLineAmount();
                InsertVATGenJournalLine(-SumVATAmount);
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
                    field(ProvisionAccountNo; ProvisionBalAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Provision Bal. Account No.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        ToolTip = 'Account root 408 on a french chart of account.';
                    }
                    field(ProvisionVATAccountNo; ProvisionVATAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Provision VAT Account No.';
                        ToolTip = 'Account root 44586 on a french chart of account.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                    }
                    field(PermanentInventoryAccountNo; PermanentInventoryAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Permanent Inventory Account No.';
                        ToolTip = 'Account root 38 on a french chart of account.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        Visible = not ExpectedCostPostingToGL;
                    }
                }
            }
        }
    }
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        PostingDate: Date;
        ProvisionBalAccountNo: Code[20];
        ProvisionVATAccountNo: Code[20];
        PermanentInventoryAccountNo: Code[20];
        GenJournalLine: Record "Gen. Journal Line";
        xPRL: Record "Purch. Rcpt. Line";
        xRSL: Record "Return Shipment Line";
        PurchaseLine: Record "Purchase Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        Vendor: Record Vendor;
        GeneralPostingSetup: Record "General Posting Setup";
        SumProvisionAmount: Decimal;
        SumVATAmount: Decimal;
        GLAccount: Record "G/L Account";
        ExpectedCostPostingToGL: Boolean;


    trigger OnInitReport()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        ExpectedCostPostingToGL := InventorySetup."Expected Cost Posting to G/L";
    end;

    trigger OnPreReport()
    var
        ErrorMsg: Label 'All parameter are required';
        ConfirmQst: Label 'Do you want to suggest purchase provisions on %1?';
        WarningMsg: Label 'Warning : This process should not be posted twice at the same posting date for the same selection!';
    begin
        if (PostingDate = 0D) or (ProvisionBalAccountNo = '') or (ProvisionVATAccountNo = '') or
            (PermanentInventoryAccountNo = '') and not ExpectedCostPostingToGL then
            Error(ErrorMsg);
        if not Confirm(ConfirmQst + '\\' + WarningMsg, false, PostingDate) then
            CurrReport.Quit();
        Initialize();
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
        TempGenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"RV Reversing Variable");
        Evaluate(TempGenJournalLine."Recurring Frequency", '<1D>');
        TempGenJournalLine.Validate("Recurring Frequency");
    end;

    local procedure Initialize()
    begin
        TempGenJournalLine.Validate("Posting Date", PostingDate);
        TempGenJournalLine.Validate("Expiration Date", PostingDate);
        TempGenJournalLine.Validate("Account No.", ProvisionBalAccountNo);

        GenJnlAllocation."Journal Template Name" := TempGenJournalLine."Journal Template Name";
        GenJnlAllocation."Journal Batch Name" := TempGenJournalLine."Journal Batch Name";
    end;

    local procedure OrderChange() ReturnValue: Boolean
    begin
        ReturnValue := PurchRcptLine."Order No." <> xPRL."Order No.";
    end;

    local procedure PurchRcptLineAllocationChange(): Boolean
    //var
    //    xInventoryPostingSetup: Record "Inventory Posting Setup";
    begin
        if PurchRcptLine.Type <> PurchRcptLine.Type::Item then
            exit(
                (PurchRcptLine."Dimension Set ID" <> xPRL."Dimension Set ID") or
                (PurchRcptLine."Gen. Bus. Posting Group" <> xPRL."Gen. Bus. Posting Group") or
                (PurchRcptLine."Gen. Prod. Posting Group" <> xPRL."Gen. Prod. Posting Group"))
        /*
        else begin
            xInventoryPostingSetup := InventoryPostingSetup;
            if ((PurchRcptLine."Posting Group" <> InventoryPostingSetup."Invt. Posting Group Code") or
                 (PurchRcptLine."Location Code" <> InventoryPostingSetup."Location Code")) then
                InventoryPostingSetup.Get(PurchRcptLine."Location Code", PurchRcptLine."Posting Group");
            exit(InventoryPostingSetup."Inventory Account" <> xInventoryPostingSetup."Inventory Account");
        end;
        */
    end;

    local procedure ReturnOrderChange() ReturnValue: Boolean
    begin
        ReturnValue := ReturnShipmentLine."Return Order No." <> xRSL."Return Order No.";
    end;

    local procedure ReturnShipmentLineAllocationChange(): Boolean
    begin
        if ReturnShipmentLine.Type <> ReturnShipmentLine.Type::Item then
            exit(
                (ReturnShipmentLine."Dimension Set ID" <> xRSL."Dimension Set ID") or
                (ReturnShipmentLine."Gen. Bus. Posting Group" <> xRSL."Gen. Bus. Posting Group") or
                (ReturnShipmentLine."Gen. Prod. Posting Group" <> xRSL."Gen. Prod. Posting Group"))
    end;

    local procedure InsertGenJournalLine(pVendorNo: Code[20]; pOrderNo: Code[20])
    begin
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GenJournalLine."External Document No." := pOrderNo;
        if pVendorNo <> Vendor."No." then
            Vendor.Get(pVendorNo);
        GenJournalLine.Description := CopyStr(Strsubstno(GenJournalLine.Description, pOrderNo, Vendor.Name), 1, maxstrlen(GenJournalLine.Description));
        GenJournalLine."IC Partner Code" := Vendor."IC Partner Code";
        GenJournalLine.Insert(true);
    end;

    local procedure InsertGenJnlAllocation(pType: Enum "Purchase Line Type"; pGenProdPostingGroup: Code[20]; pGenBusPostingGroup: Code[20]; pShortcutDimension1Code: Code[20]; pShortcutDimension2Code: Code[20]; pDimensionSetID: Integer)
    begin
        if SumProvisionAmount = 0 then
            exit;
        GenJnlAllocation.Init();
        GenJnlAllocation."Journal Line No." := GenJournalLine."Line No.";
        GenJnlAllocation."Line No." += 10000;
        if pType = pType::Item then
            GenJnlAllocation.Validate("Account No.", PermanentInventoryAccountNo)
        else begin
            if (pGenProdPostingGroup <> GeneralPostingSetup."Gen. Bus. Posting Group") or
               (pGenBusPostingGroup <> GeneralPostingSetup."Gen. Prod. Posting Group") then begin
                GeneralPostingSetup.Get(pGenProdPostingGroup, pGenBusPostingGroup);
                if GeneralPostingSetup."Purch. Account" <> GLAccount."No." then begin
                    GLAccount.Get(GeneralPostingSetup."Purch. Account");
                    GLAccount.TestField("Direct Posting", true);
                end;
            end;
            GenJnlAllocation.Validate("Account No.", GeneralPostingSetup."Purch. Account");
        end;
        if pType <> pType::Item then begin
            GenJnlAllocation."Shortcut Dimension 1 Code" := pShortcutDimension1Code;
            GenJnlAllocation."Shortcut Dimension 2 Code" := pShortcutDimension2Code;
            GenJnlAllocation."Dimension Set ID" := pDimensionSetID;
        end;
        GenJnlAllocation.Insert(true);
        GenJnlAllocation.Validate(Amount, SumProvisionAmount);
        GenJnlAllocation.Modify(true);

        GenJournalLine.Amount -= SumProvisionAmount;
        SumProvisionAmount := 0;
    end;

    local procedure UpdateGenJournalLineAmount()
    begin
        if GenJournalLine.Amount <> 0 then begin
            GenJournalLine.Validate(Amount);
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure InsertVATGenJournalLine(pVATAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
    begin
        if pVATAmount = 0 then
            exit;
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GLAccount.Get(ProvisionVATAccountNo);
        GenJournalLine.Description := GLAccount.Name;
        GenJournalLine.Validate(Amount, pVATAmount);
        GenJournalLine.Insert(true);

        GenJnlAllocation.Init();
        GenJnlAllocation."Journal Line No." := GenJournalLine."Line No.";
        GenJnlAllocation."Line No." := 10000;
        GenJnlAllocation.Insert(true);
        GenJnlAllocation.Validate("Account No.", ProvisionVATAccountNo);
        GenJnlAllocation.Validate(Amount, -GenJournalLine.Amount);
        GenJnlAllocation.Modify(true);
    end;
}
