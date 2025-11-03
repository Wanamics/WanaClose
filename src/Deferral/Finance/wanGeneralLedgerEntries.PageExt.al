pageextension 87254 "wan General Ledger Entries" extends "General Ledger Entries"
{
    layout
    {
        addafter(Amount)
        {
            field(wanStartingDate; wanDeferralLedgerEntry."Starting Date")
            {
                ApplicationArea = All;
                Visible = false;
                Caption = 'Starting Date';
                trigger OnValidate()
                begin
                    wanValidateDeferralDates();
                end;
            }
            field(wanEndingDate; wanDeferralLedgerEntry."Ending Date")
            {
                ApplicationArea = All;
                Visible = false;
                Caption = 'Ending Date';
                trigger OnValidate()
                begin
                    wanValidateDeferralDates();
                end;
            }
        }
    }
    actions
    {
        addlast(Promoted)
        {
            actionref(wanDeferralEntriesRef; wanDeferralEntries)
            {
            }
        }
        addlast(navigation)
        {
            action(wanDeferralEntries)
            {
                Caption = 'Deferral Entries';
                ApplicationArea = All;
                Image = PeriodEntries;
                Enabled = wanEnableDeferralEntries;
                trigger OnAction()
                begin
                    if wanDeferralLedgerEntry.IsEmpty then begin
                        Rec.TestField("Gen. Posting Type");
                        wanDeferralLedgerEntry."Deferral G/L Entry No." := Rec."Entry No.";
                        wanDeferralLedgerEntry."G/L Entry No." := Rec."Entry No.";
                        wanDeferralLedgerEntry."Gen. Posting Type" := Rec."Gen. Posting Type";
                        wanDeferralLedgerEntry."IC Partner Code" := Rec."IC Partner Code";
                        wanDeferralLedgerEntry."Posting Date" := Rec."Posting Date";
                        wanDeferralLedgerEntry."Starting Date" := Rec."Posting Date";
                        wanDeferralLedgerEntry."Ending Date" := Rec."Posting Date";
                        wanDeferralLedgerEntry.Insert();
                        Commit();
                        wanDeferralLedgerEntry.SetRange("Deferral G/L Entry No.", wanDeferralLedgerEntry."Deferral G/L Entry No.");
                    end;
                    RunModal(page::"wan Deferral Ledger Entries", wanDeferralLedgerEntry);
                end;
            }
        }
    }
    trigger OnAfterGetRecord()
    begin
        Clear(wanDeferralLedgerEntry);
        // if wanDeferralLedgerEntry.Get(Rec."Entry No.") then;
        wanEnableDeferralEntries := wanDeferralLedgerEntry.Get(Rec."Entry No.");
        wanDeferralLedgerEntry.SetRange("Deferral G/L Entry No.", wanDeferralLedgerEntry."Deferral G/L Entry No.");
    end;

    var
        wanEnableDeferralEntries: Boolean;
        wanDeferralLedgerEntry: Record "wan Deferral Ledger Entry";

    local procedure wanValidateDeferralDates();
    var
        DeferralDatesErr: label '%1 must be before %2';
    begin
        if not (Rec."Gen. Posting Type" in [Rec."Gen. Posting Type"::Purchase, Rec."Gen. Posting Type"::Sale]) then
            Rec.TestField("Gen. Posting Type");
        // if (wanDeferralLedgerEntry."Starting Date" = 0D) or (wanDeferralLedgerEntry."Ending Date" = 0D) then
        // exit;
        if wanDeferralLedgerEntry."G/L Entry No." <> 0 then begin
            wanDeferralLedgerEntry.Validate("Starting Date");
            wanDeferralLedgerEntry.Validate("Ending Date");
            wanDeferralLedgerEntry.Modify(true);
        end else begin
            wanDeferralLedgerEntry."G/L Entry No." := Rec."Entry No.";
            wanDeferralLedgerEntry."Gen. Posting Type" := Rec."Gen. Posting Type";
            wanDeferralLedgerEntry."IC Partner Code" := Rec."IC Partner Code";
            wanDeferralLedgerEntry."Posting Date" := Rec."Posting Date";
            wanDeferralLedgerEntry."Deferral G/L Entry No." := Rec."Entry No.";
            wanDeferralLedgerEntry.Validate("Starting Date");
            wanDeferralLedgerEntry.Validate("Ending Date");
            wanDeferralLedgerEntry.Insert(true);
        end;
    end;
}
