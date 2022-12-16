page 87220 TEMP
{
    ApplicationArea = All;
    Caption = 'TEMP';
    PageType = List;
    SourceTable = "wan Prepaid Ledger Entry";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("G/L Entry No."; Rec."G/L Entry No.")
                {
                    ToolTip = 'Specifies the value of the G/L Entry No. field.';
                }
                field("Gen. Posting Type"; Rec."Gen. Posting Type")
                {
                    ToolTip = 'Specifies the value of the Gen. Posting Type field.';
                }
                field("Posting Date"; Rec."Posting Date")
                {
                    ToolTip = 'Specifies the value of the Posting Date field.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ToolTip = 'Specifies the value of the Starting Date field.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ToolTip = 'Specifies the value of the End Date field.';
                }
                field("Prepaid G/L Entry No."; Rec."Prepaid G/L Entry No.")
                {
                    ToolTip = 'Specifies the value of the Prepaid G/L Entry No. field.';
                }
                field(Amount; Rec.Amount)
                {
                    ToolTip = 'Specifies the value of the Amount field.';
                }
            }
        }
    }
}
