pageextension 87223 "wan General Ledger Entries" extends "General Ledger Entries"
{
    layout
    {
        addafter(Amount)
        {
            field(wanStartingDate; wanPrepaidLedgerEntry."Starting Date")
            {
                ApplicationArea = All;
                Visible = false;
                Caption = 'Starting Date';
                trigger OnValidate()
                begin
                    wanValidatePrepaidDates();
                end;
            }
            field(wanEndingDate; wanPrepaidLedgerEntry."Ending Date")
            {
                ApplicationArea = All;
                Visible = false;
                Caption = 'Ending Date';
                trigger OnValidate()
                begin
                    wanValidatePrepaidDates();
                end;
            }
        }
    }
    actions
    {
        addlast(Promoted)
        {
            actionref(wanPrepaidEntriesRef; wanPrepaidEntries)
            {
            }
        }
        addlast(navigation)
        {
            action(wanPrepaidEntries)
            {
                Caption = 'Prepaid Entries';
                ApplicationArea = All;
                Image = PeriodEntries;
                Enabled = wanEnablePrepaidEntries;
                trigger OnAction()
                begin
                    RunModal(page::"wan Prepaid Ledger Entries", wanPrepaidLedgerEntry);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Clear(wanPrepaidLedgerEntry);
        wanEnablePrepaidEntries := wanPrepaidLedgerEntry.Get(Rec."Entry No.");
        wanPrepaidLedgerEntry.SetRange("Prepaid G/L Entry No.", wanPrepaidLedgerEntry."Prepaid G/L Entry No.");
    end;

    var
        wanEnablePrepaidEntries: Boolean;
        wanPrepaidLedgerEntry: Record "wan Prepaid Ledger Entry";

    local procedure wanValidatePrepaidDates();
    var
        PrepaidDatesErr: label '%1 must be before %2';
    begin
        if not (Rec."Gen. Posting Type" in [Rec."Gen. Posting Type"::Purchase, Rec."Gen. Posting Type"::Sale]) then
            Rec.TestField("Gen. Posting Type");
        //if (wanPrepaidLedgerEntry."Starting Date" > wanPrepaidLedgerEntry."Ending Date") and (wanPrepaidLedgerEntry."Ending Date" <> 0D) then
        //    Error(PrepaidDatesErr, wanPrepaidLedgerEntry.FieldCaption("Starting Date"), wanPrepaidLedgerEntry.FieldCaption("Ending Date"));
        wanPrepaidLedgerEntry.Validate("Starting Date");
        wanPrepaidLedgerEntry.Validate("Ending Date");
        if (wanPrepaidLedgerEntry."Starting Date" = 0D) or (wanPrepaidLedgerEntry."Ending Date" = 0D) then
            exit;
        if wanPrepaidLedgerEntry."G/L Entry No." <> 0 then
            wanPrepaidLedgerEntry.Modify(true)
        else begin
            wanPrepaidLedgerEntry."G/L Entry No." := Rec."Entry No.";
            wanPrepaidLedgerEntry."Gen. Posting Type" := Rec."Gen. Posting Type";
            wanPrepaidLedgerEntry."IC Partner Code" := Rec."IC Partner Code";
            wanPrepaidLedgerEntry."Posting Date" := Rec."Posting Date";
            //wanPrepaidLedgerEntry."Starting Date"
            //wanPrepaidLedgerEntry."Ending Date"
            wanPrepaidLedgerEntry."Prepaid G/L Entry No." := Rec."Entry No.";
            wanPrepaidLedgerEntry.Insert(true);
        end;
    end;
}
