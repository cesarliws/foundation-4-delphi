unit Foundation.Pattern.Defer.Test.Consts;

interface

const
  PROC_DEFER_ORDER_STEPS =
    'TDatabase.Open = foundation-db'                  + sLineBreak +
    'TDatabase.StartTransaction'                      + sLineBreak +
    'TTransaction.Query'                              + sLineBreak +
    'TQuery.Create'                                   + sLineBreak +
    'TQuery.Open(select value from table) = True'     + sLineBreak +
    'TQuery.RecordCount = 2'                          + sLineBreak +
    'TQuery.EOF = False'                              + sLineBreak +
    'TQuery.Value = 0'                                + sLineBreak +
    'TQuery.Next = True'                              + sLineBreak +
    'TQuery.EOF = False'                              + sLineBreak +
    'TQuery.Value = 1'                                + sLineBreak +
    'TQuery.Next = True'                              + sLineBreak +
    'TQuery.EOF = True'                               + sLineBreak +
    // Defer from here
    'TQuery.Close'                                    + sLineBreak +
    'TQuery.Free'                                     + sLineBreak +
    'TTransaction.Commit'                             + sLineBreak +
    'TTransaction.Free'                               + sLineBreak +
    'TDatabase.Close'                                 + sLineBreak +
    'TDatabase.Free'                                  + sLineBreak;

  EXCEPTION_BREAK_FLOW_RECORDING =
    'TDatabase.Open = foundation-db'                  + sLineBreak +
    'TDatabase.StartTransaction'                      + sLineBreak +
    // Defer from here
    'TTransaction.Commit'                             + sLineBreak +
    'TTransaction.Free'                               + sLineBreak +
    'TDatabase.Close'                                 + sLineBreak +
    'TDatabase.Free'                                  + sLineBreak;

  DELEGATE_DEFER_TO_TRACE_RECORDING =
    '> Enter DelegateDeferToTraceExecute'             + sLineBreak +
    '  1. DelegateDeferToTraceExecute: First'         + sLineBreak +
    '  2. DelegateDeferToTraceExecute: Second'        + sLineBreak +
    '  3. DelegateDeferToTraceExecute: Third'         + sLineBreak +
    '< Exit DelegateDeferToTraceExecute'              + sLineBreak;

implementation

end.
