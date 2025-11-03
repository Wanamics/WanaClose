codeunit 87260 "wan Deferral Sales Events"
{
#if OldInvoicePostBuffer
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales-Post", OnBeforePostInvPostBuffer, '', false, false)]
    local procedure OnBeforePostInvPostBuffer(var GenJnlLine: Record "Gen. Journal Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if InvoicePostBuffer."Additional Grouping Identifier" <> '' then begin
            Evaluate(GenJnlLine."wan Deferral Starting Date", CopyStr(InvoicePostBuffer."Additional Grouping Identifier", 1, 10), 9);
            Evaluate(GenJnlLine."wan Deferral Ending Date", CopyStr(InvoicePostBuffer."Additional Grouping Identifier", 11), 9);
        end;
    end;
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnPostLinesOnBeforeGenJnlLinePost, '', false, false)]
    local procedure OnPostLinesOnBeforeGenJnlLinePost(var GenJnlLine: Record "Gen. Journal Line"; SalesHeader: Record "Sales Header"; TempInvoicePostingBuffer: Record "Invoice Posting Buffer"; var GenJnlPostLine: Codeunit "Gen. Jnl.-Post Line"; PreviewMode: Boolean; SuppressCommit: Boolean)
    begin
        if TempInvoicePostingBuffer."Additional Grouping Identifier" <> '' then begin
            Evaluate(GenJnlLine."wan Deferral Starting Date", CopyStr(TempInvoicePostingBuffer."Additional Grouping Identifier", 1, 10), 9);
            Evaluate(GenJnlLine."wan Deferral Ending Date", CopyStr(TempInvoicePostingBuffer."Additional Grouping Identifier", 11), 9);
        end;
    end;


    [EventSubscriber(ObjectType::Table, Database::"Sales Header", OnBeforeSalesLineInsert, '', false, false)]
    local procedure OnBeforeSalesLineInsert(var SalesLine: Record "Sales Line"; var TempSalesLine: Record "Sales Line" temporary; SalesHeader: Record "Sales Header")
    begin
        SalesLine."wan Deferral Starting Date" := TempSalesLine."wan Deferral Starting Date";
        SalesLine."wan Deferral Ending Date" := TempSalesLine."wan Deferral Ending Date";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Release Sales Document", OnAfterReleaseSalesDoc, '', false, false)]
    local procedure OnAfterReleaseSalesDoc(var SalesHeader: Record "Sales Header"; PreviewMode: Boolean; var LinesWereModified: Boolean)
    var
        InseparableErr: Label 'and %1 are unseparable';
        DeferralTemplate: Record "Deferral Header";
        SalesLine: Record "Sales Line";
    begin
        SalesLine.SetRange("Document Type", SalesLine."Document Type");
        SalesLine.SetRange("Document No.", SalesLine."No.");
        if SalesLine.FindSet() then
            repeat
                if SalesLine."Deferral Code" <> '' then
                    if DeferralTemplate.Get(SalesLine."Deferral Code") and (DeferralTemplate."No. of Periods" = 0) then begin
                        SalesLine.TestField("wan Deferral Starting Date");
                        SalesLine.TestField("wan Deferral Ending Date");
                    end else begin
                        SalesLine.TestField("wan Deferral Starting Date", 0D);
                        SalesLine.TestField("wan Deferral Ending Date", 0D);
                    end;
                if (SalesLine."wan Deferral Starting Date" = 0D) and (SalesLine."wan Deferral Ending Date" <> 0D) then
                    SalesLine.FieldError("wan Deferral Ending Date", StrSubstNo(InseparableErr, SalesLine.FieldCaption("wan Deferral Starting Date")));
                if (SalesLine."wan Deferral Starting Date" <> 0D) and (SalesLine."wan Deferral Ending Date" = 0D) then
                    SalesLine.FieldError("wan Deferral Starting Date", StrSubstNo(InseparableErr, SalesLine.FieldCaption("wan Deferral Ending Date")));
            until SalesLine.Next() = 0;
    end;

#if OldInvoicePostBuffer
    [EventSubscriber(ObjectType::Table, Database::"Invoice Post. Buffer", OnAfterInvPostBufferPrepareSales, '', false, false)]
    local procedure OnAfterInvPostBufferPrepareSales(var SalesLine: Record "Sales Line"; var InvoicePostBuffer: Record "Invoice Post. Buffer")
    begin
        if SalesLine."wan Deferral Starting Date" <> 0D then begin
            InvoicePostBuffer."Additional Grouping Identifier" := Format(SalesLine."wan Deferral Starting Date", 0, 9) + Format(SalesLine."wan Deferral Ending Date", 0, 9);
            SalesLine."Deferral Code" := '';
        end;
    end;
#endif
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnAfterPrepareInvoicePostingBuffer, '', false, false)]
    local procedure OnAfterPrepareInvoicePostingBuffer(var SalesLine: Record "Sales Line"; var InvoicePostingBuffer: Record "Invoice Posting Buffer")
    begin
        if SalesLine."wan Deferral Starting Date" <> 0D then begin
            InvoicePostingBuffer."Additional Grouping Identifier" := Format(SalesLine."wan Deferral Starting Date", 0, 9) + Format(SalesLine."wan Deferral Ending Date", 0, 9);
            SalesLine."Deferral Code" := '';
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnBeforeGetAmountsForDeferral, '', false, false)]
    local procedure OnBeforeGetAmountsForDeferral(SalesLine: Record "Sales Line"; var AmtToDefer: Decimal; var AmtToDeferACY: Decimal; var DeferralAccount: Code[20]; var IsHandled: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        IsHandled := DeferralTemplate.Get(SalesLine."Deferral Code") and (DeferralTemplate."No. of Periods" = 0);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Sales Post Invoice Events", OnBeforePrepareLine, '', false, false)]
    local procedure OnBeforePrepareLine(SalesHeader: Record "Sales Header"; SalesLine: Record "Sales Line"; SalesLineACY: Record "Sales Line"; var IsHandled: Boolean)
    var
        DeferralTemplate: Record "Deferral Template";
    begin
        IsHandled := DeferralTemplate.Get(SalesLine."Deferral Code") and (DeferralTemplate."No. of Periods" = 0);
    end;
}