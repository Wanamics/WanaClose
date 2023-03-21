permissionset 87250 "WanaClose"
{
    Access = Internal;
    Assignable = true;
    Caption = 'WanaClose';

    Permissions =
         codeunit "wan Deferral Events" = X,
         codeunit "wan Deferral Purchase Events" = X,
         codeunit "wan Deferral Sales Events" = X,
         page "wan Deferral Ledger Entries" = X,
         report "wan Deferral Ledger Entries" = X,
         report "wan Suggest Deferral Entries" = X,
         report "wan Suggest Payable Outstd." = X,
         report "wan Suggest Outstd. Receivable" = X,
         table "wan Deferral Ledger Entry" = X,
         tabledata "wan Deferral Ledger Entry" = RIMD;
}