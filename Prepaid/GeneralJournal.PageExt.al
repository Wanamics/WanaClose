pageextension 87221 "wan General Journal" extends "General Journal"
{
    layout
    {
        addbefore("Bal. Account Type")
        {
            field("Starting Date"; Rec."wan Starting Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Starting Date field.';
            }
            field("Ending Date"; Rec."wan Ending Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Ending Date field.';
            }
        }
    }
    actions
    {
        addlast(processing)
        {
            action(wanSuggestPrepaid)
            {
                Caption = 'Suggest Prepaid Exp. & Deferred Rev.';
                Image = PeriodEntries;
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                trigger OnAction()
                var
                    SuggestPrepaidEntries: Report "wan Suggest Prepaid Entries";
                begin
                    SuggestPrepaidEntries.SetGenJournalLine(Rec);
                    SuggestPrepaidEntries.RunModal();
                    if Rec.FindFirst() then
                        CurrPage.Update(false);
                end;
            }
            action(TEMP)
            {
                Caption = 'TEMP';
                Promoted = true;
                PromotedIsBig = true;
                PromotedCategory = Process;
                ApplicationArea = All;
                RunObject = page "TEMP";
            }
        }
    }
}