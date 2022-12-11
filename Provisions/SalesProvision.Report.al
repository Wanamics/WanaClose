report 87211 "wan Suggest Sales Provisions"
{
    Caption = 'Suggest Sales Provisions';
    ProcessingOnly = true;
    dataset
    {
        dataitem(SalesShipmentLine; "Sales Shipment Line")
        {
            RequestFilterFields = "Document No.", "Sell-to Customer No.", "Order No.";
            DataItemTableView =
                sorting("Order No.", "Order Line No.", "Posting Date")
                where("Qty. Shipped Not Invoiced" = filter('<>0'));
            trigger OnPreDataItem()
            var
                DocumentNo: Label 'ToInv';
                ProvisionDescription: Label 'ToInv. %1 %2';
            begin
                SumProvisionAmount := 0;
                SumVATAmount := 0;
                TempGenJournalLine."Document No." := DocumentNo;
                TempGenJournalLine.Description := ProvisionDescription;
                SetLoadFields("Order No.", "Order Line No.", "Posting Date", "Qty. Shipped Not Invoiced");
                SetRange("Posting Date", 0D, TempGenJournalLine."Posting Date");
                SalesLine.SetLoadFields(
                    "Sell-to Customer No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit Price",
                    "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Job No.", "Job Task No.");
            end;

            trigger OnAfterGetRecord()
            var
                ProvisionAmount: Decimal;
            begin
                //if ("Posting Group" = '') or (Type <> Type::Item) /*or not ExpectedCostPostingToGL*/ then begin
                if xSSL."Document No." = '' then
                    xSSL := SalesShipmentLine;
                if (OrderChange() or PurchRcptLineAllocationChange()) and (SumProvisionAmount <> 0) then begin
                    if xSSL."Order No." <> GenJournalLine."External Document No." then begin
                        UpdateGenJournalLineAmount();
                        InsertGenJournalLine(xSSL."Sell-to Customer No.", xSSL."Order No.");
                        TempGenJournalLine."Document Date" := "Posting Date";
                    end;
                    InsertGenJnlAllocation(
                        xSSL.Type, xSSL."Gen. Bus. Posting Group", xSSL."Gen. Prod. Posting Group",
                        xSSL."Shortcut Dimension 1 Code", xSSL."Shortcut Dimension 2 Code", xSSL."Dimension Set ID");
                end;
                if ("Order No." <> SalesLine."Document No.") or ("Order Line No." <> SalesLine."Line No.") then
                    SalesLine.Get(SalesLine."Document Type"::Order, "Order No.", "Order Line No.");
                ProvisionAmount := -Round("Qty. Shipped Not Invoiced" * SalesLine."Unit Price" * SalesHeader."Currency Factor");
                SumProvisionAmount += ProvisionAmount;
                SumVATAmount += Round(ProvisionAmount * SalesShipmentLine."VAT %" / 100);
                if "Posting Date" < TempGenJournalLine."Document Date" then
                    TempGenJournalLine."Document Date" := "Posting Date";
                xSSL := SalesShipmentLine;
            end;
            //end;

            trigger OnPostDataItem()
            begin
                if SumProvisionAmount <> 0 then begin
                    UpdateGenJournalLineAmount();
                    InsertGenJournalLine(xSSL."Sell-to Customer No.", xSSL."Order No.");
                    TempGenJournalLine."Document Date" := 0D;
                end;
                InsertGenJnlAllocation(
                    xSSL.Type, xSSL."Gen. Bus. Posting Group", xSSL."Gen. Prod. Posting Group",
                    xSSL."Shortcut Dimension 1 Code", xSSL."Shortcut Dimension 2 Code", xSSL."Dimension Set ID");
                UpdateGenJournalLineAmount();
                InsertVATGenJournalLine(-SumVATAmount);
            end;
        }
        dataitem(ReturnReceiptLine; "Return Receipt Line")
        {
            RequestFilterFields = "Document No.", "Sell-to Customer No.", "Return Order No.";
            DataItemTableView =
                sorting("Return Order No.", "Return Order Line No.")
                where("Return Qty. Rcd. Not Invd." = filter('<>0'));
            trigger OnPreDataItem()
            var
                ProvisionDocumentNo: Label 'ToCM';
                ProvisionDescription: Label 'To CM %1 %2';
            begin
                SumProvisionAmount := 0;
                SumVATAmount := 0;
                TempGenJournalLine."Document No." := ProvisionDocumentNo;
                TempGenJournalLine."Description" := ProvisionDescription;
                SetLoadFields("Return Order No.", "Return Order Line No.", "Posting Date", "Return Qty. Rcd. Not Invd.");
                SetRange("Posting Date", 0D, TempGenJournalLine."Posting Date");
                SalesLine.SetLoadFields(
                    "Sell-to Customer No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit Price",
                    "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Job No.", "Job Task No.");
            end;

            trigger OnAfterGetRecord()
            var
                ProvisionAmount: Decimal;
            begin
                //if ("Posting Group" = '') or (Type <> Type::Item) /*or not ExpectedCostPostingToGL */then begin
                if xRRL."Document No." = '' then
                    xRRL := ReturnReceiptLine;
                if (ReturnOrderChange() or ReturnShipmentLineAllocationChange()) and (SumProvisionAmount <> 0) then begin
                    if xRRL."Return Order No." <> GenJournalLine."External Document No." then begin
                        UpdateGenJournalLineAmount();
                        InsertGenJournalLine(xRRL."Sell-to Customer No.", xRRL."Return Order No.");
                        TempGenJournalLine."Document Date" := "Posting Date";
                    end;
                    InsertGenJnlAllocation(
                        xRRL.Type, xRRL."Gen. Bus. Posting Group", xRRL."Gen. Prod. Posting Group",
                        xRRL."Shortcut Dimension 1 Code", xRRL."Shortcut Dimension 2 Code", xSSL."Dimension Set ID");
                end;
                if ("Return Order No." <> SalesLine."Document No.") or ("Return Order Line No." <> SalesLine."Line No.") then
                    SalesLine.Get(SalesLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.");
                ProvisionAmount := Round("Return Qty. Rcd. Not Invd." * SalesLine."Unit Cost (LCY)" * SalesHeader."Currency Factor");
                SumProvisionAmount += ProvisionAmount;
                SumVATAmount += Round(ProvisionAmount * ReturnReceiptLine."VAT %" / 100);
                if "Posting Date" < TempGenJournalLine."Document Date" then
                    TempGenJournalLine."Document Date" := "Posting Date";
                xRRL := ReturnReceiptLine;
            end;
            //end;

            trigger OnPostDataItem()
            var
                GLAccount: Record "G/L Account";
            begin
                if SumProvisionAmount <> 0 then begin
                    UpdateGenJournalLineAmount();
                    InsertGenJournalLine(xRRL."Sell-to Customer No.", xRRL."Return Order No.");
                    TempGenJournalLine."Document Date" := 0D;
                end;
                InsertGenJnlAllocation(
                    xRRL.Type, xRRL."Gen. Bus. Posting Group", xRRL."Gen. Prod. Posting Group",
                    xRRL."Shortcut Dimension 1 Code", xRRL."Shortcut Dimension 2 Code", xSSL."Dimension Set ID");
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
                    field(ProvisionBalAccountNo; ProvisionBalAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Provision Bal. Account No.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        ToolTip = 'Account root 418 on a french chart of account.';
                    }
                    field(ProvisionVATAccountNo; ProvisionVATAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Provision VAT Account No.';
                        ToolTip = 'Account root 44587 on a french chart of account.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                    }
                    /*
                    field(ProvisionAccountNo; ProvisionAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Provision Account No. (permanent inventory)';
                        ToolTip = 'Account root 38 on a french chart of account.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        Visible = not ExpectedCostPostingToGL;
                    }
                    */
                }
            }
        }
    }
    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        PostingDate: Date;
        ProvisionBalAccountNo: Code[20];
        ProvisionVATAccountNo: Code[20];
        //ProvisionAccountNo: Code[20];
        GenJournalLine: Record "Gen. Journal Line";
        xSSL: Record "Sales Shipment Line";
        xRRL: Record "Return Receipt Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        SumProvisionAmount: Decimal;
        SumVATAmount: Decimal;
        GLAccount: Record "G/L Account";
    /*
    ExpectedCostPostingToGL: Boolean;


trigger OnInitReport()
var
    InventorySetup: Record "Inventory Setup";
begin
    InventorySetup.Get();
    ExpectedCostPostingToGL := InventorySetup."Expected Cost Posting to G/L";
end;
*/

    trigger OnPreReport()
    var
        ErrorMsg: Label 'All parameter are required';
        ConfirmQst: Label 'Do you want to suggest Sales provisions on %1?';
        WarningMsg: Label 'Warning : This process should not be posted twice at the same posting date for the same selection!';
    begin
        if (PostingDate = 0D) or (ProvisionBalAccountNo = '') or (ProvisionVATAccountNo = '') /*or
            (ProvisionAccountNo = '') and not ExpectedCostPostingToGL */then
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
        ReturnValue := SalesShipmentLine."Order No." <> xSSL."Order No.";
        if ReturnValue then begin
            SalesHeader.Get(SalesHeader."Document Type"::Order, xSSL."Order No.");
            if SalesHeader."Currency Factor" = 0 then
                SalesHeader."Currency Factor" := 1;
        end;
    end;

    local procedure PurchRcptLineAllocationChange(): Boolean
    begin
        if SalesShipmentLine.Type <> SalesShipmentLine.Type::Item then
            exit(
                (SalesShipmentLine."Dimension Set ID" <> xSSL."Dimension Set ID") or
                (SalesShipmentLine."Gen. Bus. Posting Group" <> xSSL."Gen. Bus. Posting Group") or
                (SalesShipmentLine."Gen. Prod. Posting Group" <> xSSL."Gen. Prod. Posting Group"))
    end;

    local procedure ReturnOrderChange() ReturnValue: Boolean
    begin
        ReturnValue := ReturnReceiptLine."Return Order No." <> xRRL."Return Order No.";
        if ReturnValue then begin
            SalesHeader.Get(SalesHeader."Document Type"::"Return Order", xRRL."Return Order No.");
            if SalesHeader."Currency Factor" = 0 then
                SalesHeader."Currency Factor" := 1;
        end;
    end;

    local procedure ReturnShipmentLineAllocationChange(): Boolean
    begin
        if ReturnReceiptLine.Type <> ReturnReceiptLine.Type::Item then
            exit(
                (ReturnReceiptLine."Dimension Set ID" <> xRRL."Dimension Set ID") or
                (ReturnReceiptLine."Gen. Bus. Posting Group" <> xRRL."Gen. Bus. Posting Group") or
                (ReturnReceiptLine."Gen. Prod. Posting Group" <> xRRL."Gen. Prod. Posting Group"))
    end;

    local procedure InsertGenJournalLine(pCustomerNo: Code[20]; pOrderNo: Code[20])
    begin
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GenJournalLine."External Document No." := pOrderNo;
        if pCustomerNo <> Customer."No." then
            Customer.Get(pCustomerNo);
        GenJournalLine.Description := CopyStr(Strsubstno(GenJournalLine.Description, pOrderNo, Customer.Name), 1, maxstrlen(GenJournalLine.Description));
        GenJournalLine."IC Partner Code" := Customer."IC Partner Code";
        GenJournalLine.Insert(true);
    end;

    local procedure InsertGenJnlAllocation(pType: Enum "Sales Line Type"; pGenProdPostingGroup: Code[20]; pGenBusPostingGroup: Code[20]; pShortcutDimension1Code: Code[20]; pShortcutDimension2Code: Code[20]; pDimensionSetID: Integer)
    begin
        if SumProvisionAmount = 0 then
            exit;
        GenJnlAllocation.Init();
        GenJnlAllocation."Journal Line No." := GenJournalLine."Line No.";
        GenJnlAllocation."Line No." += 10000;
        /*
        if pType = pType::Item then
            GenJnlAllocation.Validate("Account No.", ProvisionAccountNo)
        else begin
            */
        if (pGenProdPostingGroup <> GeneralPostingSetup."Gen. Bus. Posting Group") or
               (pGenBusPostingGroup <> GeneralPostingSetup."Gen. Prod. Posting Group") then begin
            GeneralPostingSetup.Get(pGenProdPostingGroup, pGenBusPostingGroup);
            if GeneralPostingSetup."Purch. Account" <> GLAccount."No." then begin
                GLAccount.Get(GeneralPostingSetup."Purch. Account");
                GLAccount.TestField("Direct Posting", true);
            end;
        end;
        GenJnlAllocation.Validate("Account No.", GeneralPostingSetup."Purch. Account");
        /*
        end;
        if pType <> pType::Item then begin
        */
        GenJnlAllocation."Shortcut Dimension 1 Code" := pShortcutDimension1Code;
        GenJnlAllocation."Shortcut Dimension 2 Code" := pShortcutDimension2Code;
        GenJnlAllocation."Dimension Set ID" := pDimensionSetID;
        /*
        end;
        */
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
