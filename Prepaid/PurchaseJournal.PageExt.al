pageextension 87222 "wan Purchase Journal" extends "Purchase Journal"
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
}