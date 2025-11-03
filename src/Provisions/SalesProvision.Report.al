report 87254 "wan Suggest Outstd. Receivable"
{
    Caption = 'Suggest Outstanding Receivable';
    ProcessingOnly = true;
    dataset
    {
        dataitem(PostedLine; "Sales Shipment Line")
        {
            RequestFilterFields = "Document No.", "Sell-to Customer No.", "Order No.";
            DataItemTableView =
                sorting("Order No.", "Order Line No.", "Posting Date")
                where("Qty. Shipped Not Invoiced" = filter('<>0'));
            trigger OnPreDataItem()
            var
                DocumentNo: Label 'ToInv';
                Description: Label 'ToInv. %1 %2';
            begin
                SumOutstandingAmount := 0;
                SumVATAmount := 0;
                TempGenJournalLine."Document No." := DocumentNo;
                TempGenJournalLine.Validate("Account No.", OutstdInvAccountNo);
                TempGenJournalLine.Description := Description;
                SetLoadFields("Order No.", "Order Line No.", "Posting Date", "Qty. Shipped Not Invoiced");
                SetRange("Posting Date", 0D, TempGenJournalLine."Posting Date");
                OrderLine.SetLoadFields(
                    "Sell-to Customer No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit Cost (LCY)",
                    "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Job No.", "Job Task No.");
            end;

            trigger OnAfterGetRecord()
            var
                OutstandingAmount: Decimal;
                VATAmount: Decimal;
            begin
                if "Sell-to Customer No." <> Customer."No." then
                    Customer.Get("Sell-to Customer No.");
                if ("Posting Group" = '') /*or (Type <> Type::Item) or not ExpectedCostPostingToGL*/ then begin
                    SetGLAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    if xPostedLine."Document No." = '' then
                        xPostedLine := PostedLine;
                    if (OrderChange() or PurchRcptLineAllocationChange()) and (SumOutstandingAmount <> 0) then begin
                        if xPostedLine."Order No." <> GenJournalLine."External Document No." then begin
                            UpdateGenJournalLineAmount();
                            InsertGenJournalLine(xPostedLine."Order No.");
                            TempGenJournalLine."Document Date" := "Posting Date";
                        end;
                        InsertGenJnlAllocation(
                            xPostedLine.Type, xPostedLine."Gen. Bus. Posting Group", xPostedLine."Gen. Prod. Posting Group",
                            xPostedLine."Shortcut Dimension 1 Code", xPostedLine."Shortcut Dimension 2 Code", xPostedLine."Dimension Set ID");
                    end;
                    if ("Order No." <> OrderLine."Document No.") or ("Order Line No." <> OrderLine."Line No.") then
                        OrderLine.Get(OrderLine."Document Type"::Order, "Order No.", "Order Line No.");
                    OutstandingAmount := -Round("Qty. Shipped Not Invoiced" * OrderLine."Unit Cost (LCY)");
                    SumOutstandingAmount += OutstandingAmount;
                    VATAmount += Round(OutstandingAmount * PostedLine."VAT %" / 100);
                    SumVATAmount += VATAmount;
                    if "Posting Date" < TempGenJournalLine."Document Date" then
                        TempGenJournalLine."Document Date" := "Posting Date";
                    xPostedLine := PostedLine;
                end;
                Export(PostedLine, OutstandingAmount, VATAmount);
            end;

            trigger OnPostDataItem()
            begin
                if SumOutstandingAmount <> 0 then begin
                    UpdateGenJournalLineAmount();
                    InsertGenJournalLine(xPostedLine."Order No.");
                    TempGenJournalLine."Document Date" := 0D;
                end;
                InsertGenJnlAllocation(
                    xPostedLine.Type, xPostedLine."Gen. Bus. Posting Group", xPostedLine."Gen. Prod. Posting Group",
                    xPostedLine."Shortcut Dimension 1 Code", xPostedLine."Shortcut Dimension 2 Code", xPostedLine."Dimension Set ID");
                UpdateGenJournalLineAmount();
                InsertVATGenJournalLine(-SumVATAmount);
            end;
        }
        dataitem(ReturnLine; "Return Receipt Line")
        {
            RequestFilterFields = "Document No.", "Sell-to Customer No.", "Return Order No.";
            DataItemTableView =
                sorting("Return Order No.", "Return Order Line No.")
                where("Return Qty. Rcd. Not Invd." = filter('<>0'));
            trigger OnPreDataItem()
            var
                DocumentNo: Label 'ToCM';
                Description: Label 'To CM %1 %2';
                HoldLineNo: Integer;
            begin
                SumOutstandingAmount := 0;
                SumVATAmount := 0;
                TempGenJournalLine."Document No." := DocumentNo;
                HoldLineNo := TempGenJournalLine."Line No.";
                TempGenJournalLine."Line No." := 0;
                TempGenJournalLine.Validate("Account No.", OutstdCrMemoAccountNo);
                TempGenJournalLine."Line No." := HoldLineNo;
                TempGenJournalLine."Description" := Description;
                SetLoadFields("Return Order No.", "Return Order Line No.", "Posting Date", "Return Qty. Rcd. Not Invd.");
                SetRange("Posting Date", 0D, TempGenJournalLine."Posting Date");
                OrderLine.SetLoadFields(
                    "Sell-to Customer No.", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "Unit Cost (LCY)",
                    "Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Job No.", "Job Task No.");
            end;

            trigger OnAfterGetRecord()
            var
                OutstandingAmount: Decimal;
                VATAmount: Decimal;
            begin
                if "Sell-to Customer No." <> Customer."No." then
                    Customer.Get("Sell-to Customer No.");
                if ("Posting Group" = '') /*or (Type <> Type::Item) or not ExpectedCostPostingToGL*/ then begin
                    SetGLAccount("Gen. Bus. Posting Group", "Gen. Prod. Posting Group");
                    if xReturnLine."Document No." = '' then
                        xReturnLine := ReturnLine;
                    if (ReturnOrderChange() or ReturnShipmentLineAllocationChange()) and (SumOutstandingAmount <> 0) then begin
                        if xReturnLine."Return Order No." <> GenJournalLine."External Document No." then begin
                            UpdateGenJournalLineAmount();
                            InsertGenJournalLine(xReturnLine."Return Order No.");
                            TempGenJournalLine."Document Date" := "Posting Date";
                        end;
                        InsertGenJnlAllocation(
                            xReturnLine.Type, xReturnLine."Gen. Bus. Posting Group", xReturnLine."Gen. Prod. Posting Group",
                            xReturnLine."Shortcut Dimension 1 Code", xReturnLine."Shortcut Dimension 2 Code", xPostedLine."Dimension Set ID");
                    end;
                    if ("Return Order No." <> OrderLine."Document No.") or ("Return Order Line No." <> OrderLine."Line No.") then
                        OrderLine.Get(OrderLine."Document Type"::"Return Order", "Return Order No.", "Return Order Line No.");
                    OutstandingAmount := Round("Return Qty. Rcd. Not Invd." * OrderLine."Unit Cost (LCY)");
                    SumOutstandingAmount += OutstandingAmount;
                    VATAmount += Round(OutstandingAmount * ReturnLine."VAT %" / 100);
                    SumVATAmount += VATAmount;
                    if "Posting Date" < TempGenJournalLine."Document Date" then
                        TempGenJournalLine."Document Date" := "Posting Date";
                    xReturnLine := ReturnLine;

                    Export(ReturnLine, OutstandingAmount, VATAmount);
                end;
            end;

            trigger OnPostDataItem()
            begin
                if SumOutstandingAmount <> 0 then begin
                    UpdateGenJournalLineAmount();
                    InsertGenJournalLine(xReturnLine."Return Order No.");
                    TempGenJournalLine."Document Date" := 0D;
                end;
                InsertGenJnlAllocation(
                    xReturnLine.Type, xReturnLine."Gen. Bus. Posting Group", xReturnLine."Gen. Prod. Posting Group",
                    xReturnLine."Shortcut Dimension 1 Code", xReturnLine."Shortcut Dimension 2 Code", xPostedLine."Dimension Set ID");
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
                    field(OutstdInvAccountNo; OutstdInvAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Outstd. Receivable Inv. Account No.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        ToolTip = 'Account root 418 on a french chart of account.';
                    }
                    field(OutstdSalesCrMemoAccountNo; OutstdCrMemoAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Outstd. Receivable Cr. Memo Account No.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                        ToolTip = 'Account root 419 on a french chart of account.';
                    }
                    field(OutstdSalesVATAccountNo; OutstdVATAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Outstd. Receivable VAT Account No.';
                        ToolTip = 'Account root 44587 on a french chart of account.';
                        TableRelation = "G/L Account" where("Direct Posting" = const(true));
                    }
                    /*
                    field(ExpectedCostAccountNo; ExpectedCostAccountNo)
                    {
                        ApplicationArea = All;
                        Caption = 'Expected Inventory Account No. (permanent inventory)';
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
        OutstdInvAccountNo: Code[20];
        OutstdCrMemoAccountNo: Code[20];
        OutstdVATAccountNo: Code[20];
        //ExpectedCostAccountNo: Code[20];
        GenJournalLine: Record "Gen. Journal Line";
        xPostedLine: Record "Sales Shipment Line";
        xReturnLine: Record "Return Receipt Line";
        OrderHeader: Record "Sales Header";
        OrderLine: Record "Sales Line";
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        Customer: Record Customer;
        GeneralPostingSetup: Record "General Posting Setup";
        SumOutstandingAmount: Decimal;
        SumVATAmount: Decimal;
        GLAccount: Record "G/L Account";
        GLSetup: Record "General Ledger Setup";
        ExcelBuffer: Record "Excel Buffer" temporary;
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
        ConfirmQst: Label 'Do you want to suggest outstanding receivable on %1?';
        WarningMsg: Label 'Warning : This process should not be posted twice at the same posting date for the same selection!';
    begin
        if (PostingDate = 0D) or (OutstdInvAccountNo = '') or (OutstdVATAccountNo = '') /*or
            (ExpectedCostAccountNo = '') and not ExpectedCostPostingToGL */then
            Error(ErrorMsg);
        if not Confirm(ConfirmQst + '\\' + WarningMsg, false, PostingDate) then
            CurrReport.Quit();
        Initialize();
        GLSetup.GetRecordOnce();
        ExportOnPreReport();
    end;

    trigger OnPostReport()
    begin
        ExportOnPostReport();
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

        GenJnlAllocation."Journal Template Name" := TempGenJournalLine."Journal Template Name";
        GenJnlAllocation."Journal Batch Name" := TempGenJournalLine."Journal Batch Name";
    end;

    local procedure SetGLAccount(pGenBusPostingGroup: Code[20]; pGenProdPostingGroup: Code[20])
    begin
        if (pGenBusPostingGroup <> GeneralPostingSetup."Gen. Bus. Posting Group") or
            (pGenProdPostingGroup <> GeneralPostingSetup."Gen. Prod. Posting Group") then begin
            GeneralPostingSetup.Get(pGenBusPostingGroup, pGenProdPostingGroup);
            if GeneralPostingSetup."Purch. Account" <> GLAccount."No." then begin
                GLAccount.Get(GeneralPostingSetup."Purch. Account");
                // GLAccount.TestField("Direct Posting", true);
            end;
        end;
    end;

    local procedure OrderChange() ReturnValue: Boolean
    begin
        ReturnValue := PostedLine."Order No." <> xPostedLine."Order No.";
        // if ReturnValue then begin
        //     OrderHeader.Get(OrderHeader."Document Type"::Order, xPostedLine."Order No.");
        //     if OrderHeader."Currency Factor" = 0 then
        //         OrderHeader."Currency Factor" := 1;
    end;

    local procedure PurchRcptLineAllocationChange(): Boolean
    begin
        if PostedLine.Type <> PostedLine.Type::Item then
            exit(
                (PostedLine."Dimension Set ID" <> xPostedLine."Dimension Set ID") or
                (PostedLine."Gen. Bus. Posting Group" <> xPostedLine."Gen. Bus. Posting Group") or
                (PostedLine."Gen. Prod. Posting Group" <> xPostedLine."Gen. Prod. Posting Group"))
    end;

    local procedure ReturnOrderChange() ReturnValue: Boolean
    begin
        ReturnValue := ReturnLine."Return Order No." <> xReturnLine."Return Order No.";
        // if ReturnValue then begin
        //     OrderHeader.Get(OrderHeader."Document Type"::"Return Order", xReturnLine."Return Order No.");
        //     if OrderHeader."Currency Factor" = 0 then
        //         OrderHeader."Currency Factor" := 1;
        // end;
    end;

    local procedure ReturnShipmentLineAllocationChange(): Boolean
    begin
        if ReturnLine.Type <> ReturnLine.Type::Item then
            exit(
                (ReturnLine."Dimension Set ID" <> xReturnLine."Dimension Set ID") or
                (ReturnLine."Gen. Bus. Posting Group" <> xReturnLine."Gen. Bus. Posting Group") or
                (ReturnLine."Gen. Prod. Posting Group" <> xReturnLine."Gen. Prod. Posting Group"))
    end;

    local procedure InsertGenJournalLine(pOrderNo: Code[20])
    begin
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GenJournalLine."External Document No." := pOrderNo;
        GenJournalLine.Description := CopyStr(Strsubstno(GenJournalLine.Description, pOrderNo, Customer.Name), 1, MaxStrLen(GenJournalLine.Description));
        // GenJournalLine."IC Partner Code" := Customer."IC Partner Code";
        GenJournalLine.Insert(true);
    end;

    local procedure InsertGenJnlAllocation(pType: Enum "Sales Line Type"; pGenProdPostingGroup: Code[20]; pGenBusPostingGroup: Code[20]; pShortcutDimension1Code: Code[20]; pShortcutDimension2Code: Code[20]; pDimensionSetID: Integer)
    begin
        if SumOutstandingAmount = 0 then
            exit;
        GenJnlAllocation.Init();
        GenJnlAllocation."Journal Line No." := GenJournalLine."Line No.";
        GenJnlAllocation."Line No." += 10000;
        /*
        if pType = pType::Item then
            GenJnlAllocation.Validate("Account No.", ExpectedCostAccountNo)
        else begin
        if (pGenProdPostingGroup <> GeneralPostingSetup."Gen. Bus. Posting Group") or
               (pGenBusPostingGroup <> GeneralPostingSetup."Gen. Prod. Posting Group") then begin
            GeneralPostingSetup.Get(pGenProdPostingGroup, pGenBusPostingGroup);
            if GeneralPostingSetup."Purch. Account" <> GLAccount."No." then begin
                GLAccount.Get(GeneralPostingSetup."Purch. Account");
                GLAccount.TestField("Direct Posting", true);
            end;
        end;
        */
        GenJnlAllocation.Validate("Account No.", GeneralPostingSetup."Purch. Account");
        if pType <> pType::Item then begin
            GenJnlAllocation."Shortcut Dimension 1 Code" := pShortcutDimension1Code;
            GenJnlAllocation."Shortcut Dimension 2 Code" := pShortcutDimension2Code;
            GenJnlAllocation."Dimension Set ID" := pDimensionSetID;
        end;
        GenJnlAllocation.Insert(true);
        GenJnlAllocation.Validate(Amount, SumOutstandingAmount);
        GenJnlAllocation.Modify(true);

        GenJournalLine.Amount -= SumOutstandingAmount;
        SumOutstandingAmount := 0;
    end;

    local procedure UpdateGenJournalLineAmount()
    begin
        if GenJournalLine.Amount <> 0 then begin
            GenJournalLine.Validate(Amount);
            GenJournalLine.Modify(true);
        end;
    end;

    local procedure InsertVATGenJournalLine(pVATAmount: Decimal)
    begin
        if pVATAmount = 0 then
            exit;
        TempGenJournalLine."Line No." += 10000;
        GenJournalLine.TransferFields(TempGenJournalLine, true);
        GLAccount.Get(OutstdVATAccountNo);
        GenJournalLine.Description := GLAccount.Name;
        GenJournalLine.Validate(Amount, pVATAmount);
        GenJournalLine.Insert(true);

        GenJnlAllocation.Init();
        GenJnlAllocation."Journal Line No." := GenJournalLine."Line No.";
        GenJnlAllocation."Line No." := 10000;
        GenJnlAllocation.Insert(true);
        GenJnlAllocation.Validate("Account No.", OutstdVATAccountNo);
        GenJnlAllocation.Validate(Amount, -GenJournalLine.Amount);
        GenJnlAllocation.Modify(true);
    end;

    local procedure ExportOnPreReport()
    var
        SheetName: Label 'Data', Locked = true;
        PostedLine: Record "Sales Shipment Line";
        PurchLine: Record "Sales Line";
    begin
        ExcelBuffer.NewRow();
        AddColumn(PostedLine.FieldCaption("Document No."));
        AddColumn(PostedLine.FieldCaption("Posting Date"));
        AddColumn(PostedLine.FieldCaption("Sell-to Customer No."));
        AddColumn(Customer.FieldCaption(Name));
        AddColumn(PostedLine.FieldCaption("Order No."));
        AddColumn(PostedLine.FieldCaption(Type));
        AddColumn(PostedLine.FieldCaption("No."));
        AddColumn(PostedLine.FieldCaption(Description));
        AddColumn(PurchLine.FieldCaption("Qty. Shipped Not Invd. (Base)"));
        AddColumn(GeneralPostingSetup.FieldCaption("Purch. Account"));
        AddColumn(OrderLine.FieldCaption("VAT Base Amount"));
        AddColumn(OrderLine.FieldCaption("Amount Including VAT"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 1 Code"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 2 Code"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 3 Code"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 4 Code"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 5 Code"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 6 Code"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 7 Code"));
        AddColumn(GetDimDescription(GLSetup."Shortcut Dimension 8 Code"));
    end;

    local procedure GetDimDescription(pDimensionCode: Code[20]): Text
    var
        Dimension: Record Dimension;
    begin
        if pDimensionCode = '' then
            exit('');
        if Dimension.Get(pDimensionCode) then
            exit(Dimension."Code Caption");
    end;

    local procedure Export(var pRec: Record "Sales Shipment Line"; pAmount: Decimal; pVATAmount: Decimal)
    begin
        ExcelBuffer.NewRow();
        AddColumn(pRec."Document No.");
        AddColumn(pRec."Posting Date");
        AddColumn(pRec."Sell-to Customer No.");
        AddColumn(Customer.Name);
        AddColumn(OrderLine."Document No."); // (pRec."Order No.");
        AddColumn(pRec.Type);
        AddColumn(pRec."No.");
        AddColumn(pRec.Description);
        AddColumn(pRec."Qty. Shipped Not Invoiced");
        AddColumn(GeneralPostingSetup."Sales Account");
        AddColumn(pAmount - pVATAmount);
        AddColumn(pAmount);
        AddColumn(pRec."Shortcut Dimension 1 Code");
        AddColumn(pRec."Shortcut Dimension 2 Code");
        AddColumn(GetDimValueCode(pRec."Dimension Set ID", GLSetup."Shortcut Dimension 3 Code"));
        AddColumn(GetDimValueCode(pRec."Dimension Set ID", GLSetup."Shortcut Dimension 4 Code"));
        AddColumn(GetDimValueCode(pRec."Dimension Set ID", GLSetup."Shortcut Dimension 5 Code"));
        AddColumn(GetDimValueCode(pRec."Dimension Set ID", GLSetup."Shortcut Dimension 6 Code"));
        AddColumn(GetDimValueCode(pRec."Dimension Set ID", GLSetup."Shortcut Dimension 7 Code"));
        AddColumn(GetDimValueCode(pRec."Dimension Set ID", GLSetup."Shortcut Dimension 8 Code"));
    end;

    local procedure GetDimValueCode(pDimensionSetID: Integer; pDimensionCode: Code[20]): Text
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        if pDimensionCode = '' then
            exit('');
        if DimensionSetEntry.Get(pDimensionSetID, pDimensionCode) then
            exit(DimensionSetEntry."Dimension Value Code");
    end;

    local procedure Export(var pRec: Record "Return Receipt Line"; pAmount: Decimal; pVATAmount: Decimal)
    var
        PostedLine: Record "Sales Shipment Line";
    begin
        PostedLine.TransferFields(pRec);
        Export(PostedLine, pAmount, pVATAmount);
    end;

    local procedure ExportOnPostReport()
    var
        SheetName: Label 'Data';
    begin
        ExcelBuffer.CreateNewBook(SheetName);
        ExcelBuffer.WriteSheet(CurrReport.ObjectId(false), CompanyName, UserId);
        ExcelBuffer.CloseBook;
        ExcelBuffer.SetFriendlyFilename(CurrReport.ObjectId(true) + ' - ' + CompanyName + '-' + Format(PostingDate));
        ExcelBuffer.OpenExcel;
    end;

    local procedure AddColumn(pCellValue: Variant)
    begin
        case true of
            pCellValue.IsDate:
                ExcelBuffer."Cell Type" := ExcelBuffer."Cell Type"::Date;
            pCellValue.IsInteger, pCellValue.IsDecimal:
                ExcelBuffer."Cell Type" := ExcelBuffer."Cell Type"::Number;
            pCellValue.IsTime:
                ExcelBuffer."Cell Type" := ExcelBuffer."Cell Type"::Time;
            else
                ExcelBuffer."Cell Type" := ExcelBuffer."Cell Type"::Text;
        end;
        ExcelBuffer.AddColumn(pCellValue, false, '', false, false, false, '', ExcelBuffer."Cell Type");
    end;
}
