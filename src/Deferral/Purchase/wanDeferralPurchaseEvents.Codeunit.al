codeunit 87280 "wan Deferral Purchase Events"
{
#if OldInvoicePostBuffer
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch.-Post", OnBeforePostInvPostBuffer, '', false, false)]
    local procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if InvoicePostBuffer."Additional Grouping Identifier" <> '' then begin
            Evaluate(GenJnlLine."wan Deferral Starting Date", CopyStr(InvoicePostBuffer."Additional Grouping Identifier", 1, 10), 9);
            Evaluate(GenJnlLine."wan Deferral Ending Date", CopyStr(InvoicePostBuffer."Additional Grouping Identifier", 11), 9);
        end;
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", OnPostLinesOnBeforeGenJnlLinePost, '', false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; PurchHeader: Record "Purchase Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
        if TempInvoicePostingBuffer."Additional Grouping Identifier" <> '' then begin
            Evaluate(GenJnlLine."wan Deferral Starting Date", CopyStr(TempInvoicePostingBuffer."Additional Grouping Identifier", 1, 10), 9);
            Evaluate(GenJnlLine."wan Deferral Ending Date", CopyStr(TempInvoicePostingBuffer."Additional Grouping Identifier", 11), 9);
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Purchase Header", OnRecreatePurchLinesOnBeforeInsertPurchLine, '', false, false)]
    local procedure OnRecreatePurchLinesOnBeforeInsertPurchLine(var PurchaseLine: Record "Purchase Line"; var TempPurchaseLine: Record "Purchase Line"; ChangedFieldName: Text[100])
    begin
        PurchaseLine."wan Deferral Starting Date" := TempPurchaseLine."wan Deferral Starting Date";
        PurchaseLine."wan Deferral Ending Date" := TempPurchaseLine."wan Deferral Ending Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Purchase Document", OnAfterReleasePurchaseDoc, '', false, false)]
    local procedure OnAfterReleasePurchaseDoc(var PurchaseHeader: Record "Purchase Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        InseparableErr: Label 'and %1 are unseparable';
        DeferralTemplate: Record "Deferral Template";
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

#if OldInvoicePostBuffer
    [EventSubscriber(ObjectType::Table, Database::"Invoice Post. Buffer", OnAfterInvPostBufferPreparePurchase, '', false, false)]
    local procedure OnAfterInvPostBufferPreparePurchase(var PurchaseLine: Record "Purchase Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if PurchaseLine."wan Deferral Starting Date" <> 0D then begin
            InvoicePostBuffer."Additional Grouping Identifier" := Format(PurchaseLine."wan Deferral Starting Date", 0, 9) + Format(PurchaseLine."wan Deferral Ending Date", 0, 9);
            PurchaseLine."Deferral Code" := '';
        end;
    end;
#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", OnAfterPrepareInvoicePostingBuffer, '', false, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var PurchaseLine: Record "Purchase Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        if PurchaseLine."wan Deferral Starting Date" <> 0D then begin
            InvoicePostingBuffer."Additional Grouping Identifier" := Format(PurchaseLine."wan Deferral Starting Date", 0, 9) + Format(PurchaseLine."wan Deferral Ending Date", 0, 9);
            PurchaseLine."Deferral Code" := '';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", OnBeforeGetAmountsForDeferral, '', false, false)]
    local procedure OnBeforeGetAmountsForDeferral(PurchLine: Record "Purchase Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        IsHandled := DeferralTemplate.Get(PurchLine."Deferral Code") and (DeferralTemplate."No. of Periods" = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Purch. Post Invoice Events", OnBeforePrepareDeferralLine, '', false, false)]
    local procedure OnBeforePrepareDeferralLine(var TempDeferralHeader: Record "Deferral Header" temporary; var TempDeferralLine: Record "Deferral Line" temporary; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; AmountLCY: Decimal; AmountACY: Decimal; RemainAmtToDefer: Decimal; RemainAmtToDeferACY: Decimal; DeferralAccount: Code[20]; PurchAccount: Code[20]; DocNo: Code[20]; InvDefLineNo: Integer; var IsHandled: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        IsHandled := DeferralTemplate.Get(PurchLine."Deferral Code") and (DeferralTemplate."No. of Periods" = 0);
    end;
}