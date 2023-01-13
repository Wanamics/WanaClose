pageextension 87253 "wan General Journal" extends "General Journal"
{
    layout
    {
        addbefore("Bal. Account Type")
        {
            field("Starting Date"; Rec."wan Deferral Starting Date")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Starting Date field.';
                Visible = false;
            }
            field("Ending Date"; Rec."wan Deferral Ending Date")
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
                    Rec.TestField("wan Deferral Entry No.", 0);
                end;
            }
        }
    }
    actions
    {
        addlast(processing)
        {
            action(wanSuggestDeferral)
            {
                Caption = 'Suggest Deferral Exp. & Deferred Rev.';
                Image = PeriodEntries;
                ApplicationArea = All;
                trigger OnAction()
                var
                    SuggestDeferralEntries: Report "wan Suggest Deferral Entries";
                begin
                    SuggestDeferralEntries.SetGenJournalLine(Rec);
                    SuggestDeferralEntries.RunModal();
                    if Rec.FindFirst() then
                        CurrPage.Update(false);
                end;
            }
        }
        addlast(navigation)
        {
            action(wanDeferralEntries)
            {
                Caption = 'Deferral Entries';
                ApplicationArea = All;
                Image = PeriodEntries;
                RunObject = page "wan Deferral Ledger Entries";
                RunPageLink = "Deferral G/L Entry No." = field("wan Deferral Entry No.");
                Enabled = Rec."wan Deferral Entry No." <> 0;
            }
        }
    }
}