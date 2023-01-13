codeunit 87280 "wan Deferral Purchase Events"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", 'OnBeforePostInvPostBuffer', '', false, false)]
    local procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if InvoicePostBuffer."Additional Grouping Identifier" <> '' then begin
            Evaluate(GenJnlLine."wan Deferral Starting Date", CopyStr(InvoicePostBuffer."Additional Grouping Identifier", 1, 10), 9);
            Evaluate(GenJnlLine."wan Deferral Ending Date", CopyStr(InvoicePostBuffer."Additional Grouping Identifier", 11), 9);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", 'OnRecreatePurchLinesOnBeforeInsertPurchLine', '', false, false)]
    local procedure OnRecreatePurchLinesOnBeforeInsertPurchLine(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line"; ChangedFieldName: Text[100])
    begin
        PurchaseLine."wan Deferral Starting Date" := TempPurchaseLine."wan Deferral Starting Date";
        PurchaseLine."wan Deferral Ending Date" := TempPurchaseLine."wan Deferral Ending Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
    local procedure OnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        InseparableErr: Label 'and %1 are unseparable';
        DeferralTemplate: Record "Deferral Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."No.");
        if PurchaseLine.FindSet() then
            repeat
                if PurchaseLine."Deferral Code" <> '' then
                    if DeferralTemplate.Get(PurchaseLine."Deferral Code") and (DeferralTemplate."No. of Periods" = 0) then begin
                        PurchaseLine.TestField("wan Deferral Starting Date");
                        PurchaseLine.TestField("wan Deferral Ending Date");
                    end else begin
                        PurchaseLine.TestField("wan Deferral Starting Date", 0D);
                        PurchaseLine.TestField("wan Deferral Ending Date", 0D);
                    end;
                if (PurchaseLine."wan Deferral Starting Date" = 0D) and (PurchaseLine."wan Deferral Ending Date" <> 0D) then
                    PurchaseLine.FieldError("wan Deferral Ending Date", StrSubstNo(InseparableErr, PurchaseLine.FieldCaption("wan Deferral Starting Date")));
                if (PurchaseLine."wan Deferral Starting Date" <> 0D) and (PurchaseLine."wan Deferral Ending Date" = 0D) then
                    PurchaseLine.FieldError("wan Deferral Starting Date", StrSubstNo(InseparableErr, PurchaseLine.FieldCaption("wan Deferral Ending Date")));
            until PurchaseLine.Next() = 0;
    end;

    /*
        [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", 'OnAfterReleasePurchaseDoc', '', false, false)]
        local procedure OnAfterReopenPurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean)
        var
            Line: Record "Purchase Line";
            DeferralTemplate: Record "Deferral Template";
            InseparableErr: Label 'and %1 are unseparable';
        begin
            if PreviewMode then
                exit;
            Line.SetRange("Document Type", PurchaseHeader."Document Type");
            Line.SetRange("Document No.", PurchaseHeader."No.");
            Line.SetFilter(Quantity, '<>0');
            if Line.FindSet() then
                repeat
                    if Line."Deferral Code" <> '' then
                        if DeferralTemplate.Get(Line."Deferral Code") and (DeferralTemplate."No. of Periods" = 0) then begin
                            Line.TestField("wan Deferral Starting Date");
                            Line.TestField("wan Deferral Ending Date");
                        end else begin
                            Line.TestField("wan Deferral Starting Date", 0D);
                            Line.TestField("wan Deferral Ending Date", 0D);
                        end;
                    if (Line."wan Deferral Starting Date" <> 0D) xor (Line."wan Deferral Ending Date" <> 0D) then
                        Line.FieldError("wan Deferral Starting Date", StrSubstNo(InseparableErr, Line.FieldCaption("wan Deferral Ending Date")));
                until Line.Next() = 0;
        end;
    */
    [EventSubscriber(ObjectType::Table, Database::"Invoice Post. Buffer", 'OnAfterInvPostBufferPreparePurchase', '', false, false)]
    local procedure OnAfterInvPostBufferPreparePurchase(var PurchaseLine: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if PurchaseLine."wan Deferral Starting Date" <> 0D then begin
            InvoicePostBuffer."Additional Grouping Identifier" := Format(PurchaseLine."wan Deferral Starting Date", 0, 9) + Format(PurchaseLine."wan Deferral Ending Date", 0, 9);
            PurchaseLine."Deferral Code" := '';
        end;
    end;
}