pageextension 87223 "wan General Journal" extends "General Journal"
{
    layout
    {
        addbefore("Bal. Account Type")
        {
            field("Starting Date"; Rec."wan Starting Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Starting Date field.';
                Visible = false;
            }
            field("Ending Date"; Rec."wan Ending Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Ending Date field.';
                Visible = false;
            }
            field("IC Partner Code"; Rec."IC Partner Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the IC Partner Code field.';
                Visible = false;
                Editable = true;
                trigger OnValidate()
                begin
                    if Rec."IC Partner Code" = xRec."IC Partner Code" then
                        exit;
                    Rec.TestField("Account Type", Rec."Account Type"::"G/L Account");
                    Rec.TestField("Bal. Account Type", Rec."Bal. Account Type"::"G/L Account");
                    Rec.TestField("wan Prepaid Entry No.", 0);
                end;
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
                //Promoted = true;
                //PromotedIsBig = true;
                //PromotedCategory = Process;
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
        }
        addlast(navigation)
        {
            action(wanPrepaidEntries)
            {
                Caption = 'Prepaid Entries';
                //Promoted = true;
                //PromotedIsBig = true;
                //PromotedCategory = Process;
                ApplicationArea = All;
                Image = PeriodEntries;
                RunObject = page "wan Prepaid Ledger Entries";
                RunPageLink = "Prepaid G/L Entry No." = field("wan Prepaid Entry No.");
                Enabled = Rec."wan Prepaid Entry No." <> 0;
            }
        }
    }
}