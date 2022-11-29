pageextension 87210 "wan Recurring General Journal" extends "Recurring General Journal"
{
    actions
    {
        addlast("F&unctions")
        {
            action(wanSuggest)
            {
                Caption = 'Suggest Rcpt. not Invoiced';
                Image = ReceiptLines;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    PurchRcptNotInv: Report "wan Purch. Rcpt. not Inv.";
                begin
                    PurchRcptNotInv.SetInitGenJournalLine(Rec);
                    PurchRcptNotInv.RunModal();
                    if Rec.FindFirst() then
                        CurrPage.Update(false);
                end;
            }
        }
    }
}
