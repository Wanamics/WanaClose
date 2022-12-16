pageextension 87210 "wan Recurring General Journal" extends "Recurring General Journal"
{
    actions
    {
        addlast(processing)
        {
            action(wanSuggestProvisions)
            {
                Caption = 'Suggest Purchase Provisions';
                Image = ReceiptLines;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    SuggestProvisions: Report "wan Suggest Purch. Provisions";
                begin
                    SuggestProvisions.SetGenJournalLine(Rec);
                    SuggestProvisions.RunModal();
                    if Rec.FindFirst() then
                        CurrPage.Update(false);
                end;
            }
            action(wanSuggestSalesProvisions)
            {
                Caption = 'Suggest Sales Provisions';
                Image = ReceiptLines;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    SuggestProvisions: Report "wan Suggest Sales Provisions";
                begin
                    SuggestProvisions.SetGenJournalLine(Rec);
                    SuggestProvisions.RunModal();
                    if Rec.FindFirst() then
                        CurrPage.Update(false);
                end;
            }
        }
    }
}
