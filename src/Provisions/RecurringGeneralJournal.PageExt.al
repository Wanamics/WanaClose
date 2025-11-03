pageextension 87250 "wan Recurring General Journal" extends "Recurring General Journal"
{
    actions
    {
        addlast(processing)
        {
            action(wanSuggestPayableOutstanding)
            {
                Caption = 'Suggest Payable Outstanding';
                Image = ReceiptLines;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    SuggestPayableOutstd: Report "wan Suggest Payable Outstd.";
                begin
                    SuggestPayableOutstd.SetGenJournalLine(Rec);
                    SuggestPayableOutstd.RunModal();
                    if Rec.FindFirst() then
                        CurrPage.Update(false);
                end;
            }
            action(wanSuggestReceivableOutstanding)
            {
                Caption = 'Suggest Receivable Outstanding';
                Image = ReceiptLines;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    SuggestReceivableOutstd: Report "wan Suggest Outstd. Receivable";
                begin
                    SuggestReceivableOutstd.SetGenJournalLine(Rec);
                    SuggestReceivableOutstd.RunModal();
                    if Rec.FindFirst() then
                        CurrPage.Update(false);
                end;
            }
        }
    }
}
