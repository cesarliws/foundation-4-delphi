unit Foundation.Vendor.JclDebug;

{**************************************************************************************************}
{                                                                                                  }
{ Foundation.Vendor.JclDebug                                                                       }
{ This file in under the original license terms of Project Jedi                                    }
{                                                                                                  }
{ This unit is included only to make easy to test without have to install Jedi JCL, for production }
{ please use original JclDebug.pas.                                                                }
{                                                                                                  }
{ Included only the necessary parts used to extract the caller method address, extracted from:     }
{ - JclDebug.pas                                                                                   }
{ - JclWin32.pas                                                                                   }
{ - JclBase.pas                                                                                    }
{                                                                                                  }
{**************************************************************************************************}
{ Project JEDI Code Library (JCL)                                                                  }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is JclDebug.pas.                                                               }
{                                                                                                  }
{ The Initial Developers of the Original Code are Petr Vones and Marcel van Brakel.                }
{ Portions created by these individuals are Copyright (C) of these individuals.                    }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{ Contributor(s):                                                                                  }
{   Marcel van Brakel                                                                              }
{   Flier Lu (flier)                                                                               }
{   Florent Ouchet (outchy)                                                                        }
{   Robert Marquardt (marquardt)                                                                   }
{   Robert Rossmair (rrossmair)                                                                    }
{   Andreas Hausladen (ahuser)                                                                     }
{   Petr Vones (pvones)                                                                            }
{   Soeren Muehlbauer                                                                              }
{   Uwe Schuster (uschuster)                                                                       }
{                                                                                                  }
{**************************************************************************************************}

interface

{$IFNDEF CPUX86}
   {$Message Warn 'This unit is only for Windows 32-bit, use Jedi JCL JclDebug instead.'}
{$ENDIF CPUX86}

function Caller(Level: Integer; FastStackWalk: Boolean = True): Pointer;

implementation

uses
  WinApi.Windows;

type
  TJclAddr = Cardinal;
  PStackFrame = ^TStackFrame;
  TStackFrame = record
    CallerFrame: TJclAddr;
    CallerAddr: TJclAddr;
  end;

type
  NT_TIB32 = packed record
    ExceptionList: DWORD;
    StackBase: DWORD;
    StackLimit: DWORD;
    SubSystemTib: DWORD;
    case Integer of
      0 : (
        FiberData: DWORD;
        ArbitraryUserPointer: DWORD;
        Self: DWORD;
      );
      1 : (
        Version: DWORD;
      );
  end;
  {$EXTERNALSYM NT_TIB32}
  PNT_TIB32 = ^NT_TIB32;
  {$EXTERNALSYM PNT_TIB32}

function GetFramePointer: Pointer;
asm
        MOV     EAX, EBP
end;

function GetStackTop: TJclAddr;
asm
        MOV     EAX, FS:[0].NT_TIB32.StackBase
end;

function Caller(Level: Integer; FastStackWalk: Boolean = True): Pointer;
var
  BaseOfStack : TJclAddr;
  StackFrame  : PStackFrame;
  TopOfStack  : TJclAddr;
begin
  Result := nil;
  try
    StackFrame  := GetFramePointer;
    BaseOfStack := TJclAddr(StackFrame) - 1;
    TopOfStack  := GetStackTop;

    while (BaseOfStack < TJclAddr(StackFrame)) and (TJclAddr(StackFrame) < TopOfStack) do
    begin
      if Level = 0 then
      begin
        Result := Pointer(StackFrame^.CallerAddr - 1);
        Break;
      end;

      StackFrame := PStackFrame(StackFrame^.CallerFrame);
      Dec(Level);
    end;
  except
    Result := nil;
  end;
end;

end.
