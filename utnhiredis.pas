UNIT utnhiredis;

{$MODE OBJFPC}
{$MACRO ON}

{$IFDEF FPC}
  {$PACKRECORDS C}
{$ENDIF}


////////////////////////////////////////////////////////////////////////////////
INTERFACE


USES 
  unixtype, ctypes;


TYPE
  
  { Reply }

  PredisReply = ^redisReply;
  redisReply = record
    _type     : longint;
    integer   : int64;
    len       : longint;
    str       : ^char;
    elements  : size_t;
    element   : ^PredisReply;
  end;  

  { Read Task }
  
  PredisReadTask  = ^redisReadTask;
  redisReadTask = record
    _type     : longint;
    elements  : longint;                      { number of elements in multibulk container  }
    idx       : longint;                      { index in parent (array) object  }
    obj       : pointer;                      { holds user-generated value for a read task  }
    parent    : ^redisReadTask;               { parent task  }
    privdata  : pointer;                      { user-settable arbitrary field  }
  end;

  { Reply Object Functions }
  
  redisReplyObjectFunctions = record
    createString  : function  (_para1:PredisReadTask; _para2:Pchar; _para3:size_t):pointer;cdecl;
    createArray   : function  (_para1:PredisReadTask; _para2:longint):pointer;cdecl;
    createInteger : function  (_para1:PredisReadTask; _para2:int64):pointer;cdecl;
    createNil     : function  (_para1:PredisReadTask):pointer;cdecl;
    freeObject    : procedure (_para1:pointer);cdecl;
  end;

  { Reader }
  
  PredisReader  = ^redisReader;
  redisReader = record
    err       : longint;                      { Error flags, 0 when there is no error  }
    errstr    : array[0..127] of char;        { String representation of error when applicable  }
    buf       : ^char;                        { Read buffer  }
    pos       : size_t;                       { Buffer cursor  }
    len       : size_t;                       { Buffer length  }
    maxbuf    : size_t;                       { Max length of unused buffer  }
    rstack    : array[0..8] of redisReadTask;
    ridx      : longint;                      { Index of current read task  }
    reply     : pointer;                      { Temporary reply pointer  }
    fn        : ^redisReplyObjectFunctions;
    privdata  : pointer;
  end;
      
  { Context }
  
  PredisContext  = ^redisContext; 
  redisContext = record
    err       : longint;                      { Error flags, 0 when there is no error  }
    errstr    : array[0..127] of char;        { String representation of error when applicable  }
    fd        : longint;
    flags     : longint;
    obuf      : ^char;                        { Write buffer  }
    reader    : PredisReader;                 { Protocol reader  }
  end;


CONST

  lib_hiredis = 'libhiredis';

  HIREDIS_MAJOR             = 0;    
  HIREDIS_MINOR             = 11;    
  HIREDIS_PATCH             = 0;    
  REDIS_ERR                 = -(1);    
  REDIS_OK                  = 0;    

  { When an error occurs, the err flag in a context is set to hold the type of
   * error that occured. REDIS_ERR_IO means there was an I/O error and you
   * should use the "errno" variable to find out what is wrong.
   * For other values, the "errstr" field will hold a description.  }
  REDIS_ERR_IO              = 1;    { Error in read or write  }  
  REDIS_ERR_EOF             = 3;    { End of file  }  
  REDIS_ERR_PROTOCOL        = 4;    { Protocol error  }  
  REDIS_ERR_OOM             = 5;    { Out of memory  }  
  REDIS_ERR_OTHER           = 2;    { Everything else...  }  
  REDIS_BLOCK               = $1;   { Connection type can be blocking or non-blocking and is set in the least significant bit of the flags field in redisContext.  }   
  REDIS_CONNECTED           = $2;   { Connection may be disconnected before being free'd. The second bit in the flags field is set when the context is connected.  }   

  { The async API might try to disconnect cleanly and flush the output
   * buffer and read all subsequent replies before disconnecting.
   * This flag means no new commands can come in and the connection
   * should be terminated once all replies have been read.  }
  REDIS_DISCONNECTING       = $4;    
  REDIS_FREEING             = $8;   { Flag specific to the async API which means that the context should be clean up as soon as possible.  } 
  REDIS_IN_CALLBACK         = $10;  { Flag that is set when an async callback is executed.  }  
  REDIS_SUBSCRIBED          = $20;  { Flag that is set when the async context has one or more subscriptions.  }  
  REDIS_MONITORING          = $40;  { Flag that is set when monitor mode is active  }  
  REDIS_REPLY_STRING        = 1;    
  REDIS_REPLY_ARRAY         = 2;    
  REDIS_REPLY_INTEGER       = 3;    
  REDIS_REPLY_NIL           = 4;    
  REDIS_REPLY_STATUS        = 5;    
  REDIS_REPLY_ERROR         = 6;    
  REDIS_READER_MAX_BUF      = 1024 * 16;  { Default max unused reader buffer.  }  
  REDIS_KEEPALIVE_INTERVAL  = 15;   { seconds  }  
      


//------------------------------------------------------------------------------
//  Library API - External Declarations
//------------------------------------------------------------------------------

function  c_redisReaderCreate ( ):PredisReader; 
  cdecl; external lib_hiredis name 'redisReaderCreate';

procedure c_redisReaderFree ( r:PredisReader ); 
  cdecl; external lib_hiredis name 'redisReaderFree';

function  c_redisReaderFeed ( r:PredisReader; buf:Pchar; len:size_t ):longint; 
  cdecl; external lib_hiredis name 'redisReaderFeed';

function  c_redisReaderGetReply ( r:PredisReader; reply:Ppointer ):longint; 
  cdecl; external lib_hiredis name 'redisReaderGetReply';

{
function  c_redisReplyReaderSetPrivdata ( _r,_p : longint ) : longint; 
  cdecl; external lib_hiredis name 'redisReplyReaderSetPrivdata';

function  c_redisReplyReaderGetObject ( _r : longint ) : longint; 
  cdecl; external lib_hiredis name 'redisReplyReaderGetObject';

function  c_redisReplyReaderGetError ( _r : longint ) : longint; 
  cdecl; external lib_hiredis name 'redisReplyReaderGetError';
}

procedure c_freeReplyObject ( reply:pointer ); 
  cdecl; external lib_hiredis name 'freeReplyObject';

{
function  redisvFormatCommand ( target:PPchar; format:Pchar; ap:va_list ):longint; 
  cdecl; external lib_hiredis name 'redisvFormatCommand';

function  c_redisFormatCommand ( target:PPchar; format:Pchar; args:array of const ):longint; 
  cdecl; external lib_hiredis name 'redisFormatCommand';
}

function  c_redisFormatCommandArgv ( target:PPchar; argc:longint; argv:PPchar; argvlen:Psize_t ):longint; 
  cdecl; external lib_hiredis name 'redisFormatCommandArgv';

function  c_redisConnect ( ip:Pchar; port:longint ):PredisContext; 
  cdecl; external lib_hiredis name 'redisConnect';

function  c_redisConnectWithTimeout ( ip:Pchar; port:longint; tv:timeval ):PredisContext; 
  cdecl; external lib_hiredis name 'redisConnectWithTimeout';

function  c_redisConnectNonBlock ( ip:Pchar; port:longint ):PredisContext; 
  cdecl; external lib_hiredis name 'redisConnectNonBlock';

function  c_redisConnectUnix ( path:Pchar ):PredisContext; 
  cdecl; external lib_hiredis name 'redisConnectUnix';

function  c_redisConnectUnixWithTimeout ( path:Pchar; tv:timeval ):PredisContext; 
  cdecl; external lib_hiredis name 'redisConnectUnixWithTimeout';

function  c_redisConnectUnixNonBlock ( path:Pchar ):PredisContext; 
  cdecl; external lib_hiredis name 'redisConnectUnixNonBlock';

function  c_redisSetTimeout ( c:PredisContext; tv:timeval ):longint; 
  cdecl; external lib_hiredis name 'redisSetTimeout';

function  c_redisEnableKeepAlive ( c:PredisContext ):longint; 
  cdecl; external lib_hiredis name 'redisEnableKeepAlive';

procedure c_redisFree ( c:PredisContext ); 
  cdecl; external lib_hiredis name 'redisFree';

function  c_redisBufferRead ( c:PredisContext ):longint; 
  cdecl; external lib_hiredis name 'redisBufferRead';

function  c_redisBufferWrite ( c:PredisContext; done:Plongint ):longint; 
  cdecl; external lib_hiredis name 'redisBufferWrite';

function  c_redisGetReply ( c:PredisContext; reply:Ppointer ):longint; 
  cdecl; external lib_hiredis name 'redisGetReply';

function  c_redisGetReplyFromReader ( c:PredisContext; reply:Ppointer ):longint; 
  cdecl; external lib_hiredis name 'redisGetReplyFromReader';

{
function  redisvAppendCommand ( c:PredisContext; format:Pchar; ap:va_list ):longint; 
  cdecl; external 'libhiredis' name 'redisvAppendCommand';
}

function  c_redisAppendCommand ( c:PredisContext; format:Pchar; args:array of const ):longint; 
  cdecl; external 'libhiredis' name 'redisAppendCommand';

function  c_redisAppendCommandArgv ( c:PredisContext; argc:longint; argv:PPchar; argvlen:Psize_t ):longint; 
  cdecl; external lib_hiredis name 'redisAppendCommandArgv';

{
function  redisvCommand ( c:PredisContext; format:Pchar; ap:va_list ):pointer; 
  cdecl; external lib_hiredis name 'redisCommand';
}

function  c_redisCommand ( c:PredisContext; format:Pchar; args:array of const ):pointer; 
  cdecl; external lib_hiredis name 'redisCommand';

function  c_redisCommandArgv ( c:PredisContext; argc:longint; argv:PPchar; argvlen:Psize_t ):pointer; 
  cdecl; external lib_hiredis name 'redisCommandArgv';


//------------------------------------------------------------------------------
//  Public API - FP Interface
//------------------------------------------------------------------------------

function  fp_redisReaderCreate ( ):PredisReader;
procedure fp_redisReaderFree ( r:PredisReader );
function  fp_redisReaderFeed ( r:PredisReader; buf:Pchar; len:size_t ):longint;
function  fp_redisReaderGetReply ( r:PredisReader; reply:Ppointer ):longint;

{
function  fp_redisReplyReaderSetPrivdata ( _r,_p : longint ):longint;  // was #define dname(params) para_def_expr / argument types are unknown 
function  fp_redisReplyReaderGetObject ( _r : longint ):longint;  // was #define dname(params) para_def_expr / argument types are unknown / return type might be wrong    
function  fp_redisReplyReaderGetError ( _r : longint ):longint;  // was #define dname(params) para_def_expr / argument types are unknown / return type might be wrong    
}

procedure fp_freeReplyObject ( reply:pointer ); { Function to free the reply objects hiredis returns by default. }

{
function  fp_redisvFormatCommand ( target:PPchar; format:Pchar; ap:va_list ):longint; // Functions to format a command according to the protocol. 
}

function  fp_redisFormatCommand ( target:PPchar; format:Pchar; args:array of const ):longint; 
function  fp_redisFormatCommandArgv ( target:PPchar; argc:longint; argv:PPchar; argvlen:Psize_t ):longint;
function  fp_redisConnect ( ip:Pchar; port:longint ):PredisContext;
function  fp_redisConnectWithTimeout ( ip:Pchar; port:longint; tv:timeval ):PredisContext;
function  fp_redisConnectNonBlock ( ip:Pchar; port:longint ):PredisContext;
function  fp_redisConnectUnix ( path:Pchar ):PredisContext;
function  fp_redisConnectUnixWithTimeout ( path:Pchar; tv:timeval ):PredisContext;
function  fp_redisConnectUnixNonBlock ( path:Pchar ):PredisContext;
function  fp_redisSetTimeout ( c:PredisContext; tv:timeval ):longint;
function  fp_redisEnableKeepAlive ( c:PredisContext ):longint;
procedure fp_redisFree ( c:PredisContext);
function  fp_redisBufferRead ( c:PredisContext ):longint;
function  fp_redisBufferWrite ( c:PredisContext; done:Plongint ):longint;

{ In a blocking context, this function first checks if there are unconsumed
 * replies to return and returns one if so. Otherwise, it flushes the output
 * buffer to the socket and reads until it has a reply. In a non-blocking
 * context, it will return unconsumed replies until there are no more.  }
function  fp_redisGetReply ( c:PredisContext; reply:Ppointer ):longint;
function  fp_redisGetReplyFromReader ( c:PredisContext; reply:Ppointer ):longint;
  
{
function  fp_redisvAppendCommand ( c:PredisContext; format:Pchar; ap:va_list):longint;  // Write a command to the output buffer. Use these functions in blocking mode to get a pipeline of commands. 
}

function  fp_redisAppendCommand ( c:PredisContext; format:Pchar; args:array of const ):longint; 
function  fp_redisAppendCommandArgv ( c:PredisContext; argc:longint; argv:PPchar; argvlen:Psize_t ):longint;

{ Issue a command to Redis. In a blocking context, it is identical to calling
 * redisAppendCommand, followed by redisGetReply. The function will return
 * NULL if there was an error in performing the request, otherwise it will
 * return the reply. In a non-blocking context, it is identical to calling
 * only redisAppendCommand and will always return NULL.  }
{
function  fp_redisvCommand ( c:PredisContext; format:Pchar; ap:va_list):pointer;  
}

function  fp_redisCommand ( c:PredisContext; format:Pchar; args:array of const ):pointer; 
function  fp_redisCommandArgv ( c:PredisContext; argc:longint; argv:PPchar; argvlen:Psize_t ):pointer;


{$define fp_redisReplyReaderCreate:=fp_redisReaderCreate}
{$define fp_redisReplyReaderFree:=fp_redisReaderFree}
{$define fp_redisReplyReaderFeed:=fp_redisReaderFeed}    
{$define fp_redisReplyReaderGetReply:=fp_redisReaderGetReply}


////////////////////////////////////////////////////////////////////////////////
IMPLEMENTATION


//------------------------------------------------------------------------------
function fp_redisReaderCreate ( ):PredisReader;
begin
  Result := c_redisReaderCreate();
end;

//------------------------------------------------------------------------------
procedure fp_redisReaderFree ( r:PredisReader );
begin
  c_redisReaderFree(r);
end;

//------------------------------------------------------------------------------
function fp_redisReaderFeed ( r:PredisReader; buf:Pchar; len:size_t ):longint;
begin
  Result := c_redisReaderFeed(r, buf, len);
end;

//------------------------------------------------------------------------------
function fp_redisReaderGetReply ( r:PredisReader; reply:Ppointer ):longint;
begin
  Result := c_redisReaderGetReply(r, reply);
end;


{ was #define dname(params) para_def_expr / argument types are unknown }
{
//------------------------------------------------------------------------------
function fp_redisReplyReaderSetPrivdata(_r,_p : longint) : longint;
begin
//    longint((predisReader(_r))^.privdata):=_p;
//    redisReplyReaderSetPrivdata := longint((predisReader(_r))^.privdata);
  Result := c_redisReplyReaderSetPrivdata(_r, _p);
end;
}

{ was #define dname(params) para_def_expr / argument types are unknown / return type might be wrong }   
{
//------------------------------------------------------------------------------
function fp_redisReplyReaderGetObject(_r : longint) : longint;
begin
  //(predisReader(_r))^.reply;
  Result := c_redisReplyReaderGetObject(_r);
end;
}

{ was #define dname(params) para_def_expr / argument types are unknown / return type might be wrong }   
{
//------------------------------------------------------------------------------
function fp_redisReplyReaderGetError(_r : longint) : longint;
begin
  //(predisReader(_r))^.errstr;
  Result := c_redisReplyReaderGetError(_r);
end;
}

//------------------------------------------------------------------------------
procedure fp_freeReplyObject ( reply:pointer );
begin
  c_freeReplyObject(reply);
end;

//  *** no support for va_list ***
{
//------------------------------------------------------------------------------
function fp_redisvFormatCommand(target:PPchar; format:Pchar; ap:va_list):longint;
begin
end;
}

//------------------------------------------------------------------------------
function fp_redisFormatCommand ( target:PPchar; format:Pchar; args:array of const ):longint;
begin
  Result := fp_redisFormatCommand(target,  format, [@args]);
end;

//------------------------------------------------------------------------------
function fp_redisFormatCommandArgv ( target:PPchar; argc:longint; argv:PPchar; argvlen:Psize_t ):longint;
begin
  Result := c_redisFormatCommandArgv(target, argc, argv, argvlen);
end;

//------------------------------------------------------------------------------
function fp_redisConnect ( ip:Pchar; port:longint ):PredisContext;
begin
  Result := c_redisConnect(ip, port);
end;

//------------------------------------------------------------------------------
function fp_redisConnectWithTimeout ( ip:Pchar; port:longint; tv:timeval ):PredisContext;
begin
  Result := c_redisConnectWithTimeout(ip, port, tv);
end;

//------------------------------------------------------------------------------
function fp_redisConnectNonBlock ( ip:Pchar; port:longint ):PredisContext;
begin
  Result := c_redisConnectNonBlock(ip, port);
end;

//------------------------------------------------------------------------------
function fp_redisConnectUnix ( path:Pchar ):PredisContext;
begin
  Result := c_redisConnectUnix(path);
end;

//------------------------------------------------------------------------------
function fp_redisConnectUnixWithTimeout ( path:Pchar; tv:timeval ):PredisContext;
begin
  Result := c_redisConnectUnixWithTimeout(path, tv)
end;

//------------------------------------------------------------------------------
function fp_redisConnectUnixNonBlock ( path:Pchar ):PredisContext;
begin
  Result := c_redisConnectUnixNonBlock(path);
end;

//------------------------------------------------------------------------------
function fp_redisSetTimeout ( c:PredisContext; tv:timeval ):longint;
begin
  Result := c_redisSetTimeout(c, tv);
end;

//------------------------------------------------------------------------------
function fp_redisEnableKeepAlive ( c:PredisContext ):longint;
begin
  Result := c_redisEnableKeepAlive(c);
end;

//------------------------------------------------------------------------------
procedure fp_redisFree ( c:PredisContext );
begin
  c_redisFree(c);
end;

//------------------------------------------------------------------------------
function fp_redisBufferRead ( c:PredisContext ):longint;
begin
  Result := c_redisBufferRead(c);
end;

//------------------------------------------------------------------------------
function fp_redisBufferWrite ( c:PredisContext; done:Plongint ):longint;
begin
  Result := c_redisBufferWrite(c, done);
end;

//------------------------------------------------------------------------------
function fp_redisGetReply ( c:PredisContext; reply:Ppointer ):longint;
begin
  Result := c_redisGetReply(c, reply)
end;

//------------------------------------------------------------------------------
function fp_redisGetReplyFromReader ( c:PredisContext; reply:Ppointer ):longint;
begin
  Result := c_redisGetReplyFromReader(c, reply);
end;

//  *** no support for va_list ***
{ 
//------------------------------------------------------------------------------
function fp_redisvAppendCommand(c:PredisContext; format:Pchar; ap:va_list):longint;
begin
  Result := 0;
end;
}

//------------------------------------------------------------------------------
function fp_redisAppendCommand ( c:PredisContext; format:Pchar; args:array of const ):longint;
begin
  Result := c_redisAppendCommand(c, format, [@args]);
end;
         
//------------------------------------------------------------------------------
function fp_redisAppendCommandArgv ( c:PredisContext; argc:longint; argv:PPchar; argvlen:Psize_t ):longint;
begin
  Result := c_redisAppendCommandArgv(c, argc, argv, argvlen);
end;

//  *** no support for va_list ***
{ 
//------------------------------------------------------------------------------
function fp_redisvCommand(c:PredisContext; format:Pchar; ap:va_list):pointer;
begin
  Result := Nil;
end;
}

//------------------------------------------------------------------------------
function fp_redisCommand ( c:PredisContext; format:Pchar; args:array of const ):pointer;
var 
  i,j:longint;
  varg:Array of TVarRec;
begin
  i := length(args)-1;
  if ( i >= -1 ) then
  begin
   
    setlength(varg,i + 1);
    for j := 0 to i do
      varg[j] := args[j]; 

    case i of
     -1:begin
          writeln('0 arguments');
          Result := c_redisCommand(c, format, []);
        end;
      0:begin
          writeln('1 argument');
          Result := c_redisCommand(c, format, [varg[0].VAnsiString]);
        end;
      1:begin
          writeln('2 arguments');
          Result := c_redisCommand(c, format, [varg[0].VAnsiString, varg[1].VAnsiString]);
        end;
      2:begin
          writeln('3 arguments');
          Result := c_redisCommand(c, format, [varg[0].VAnsiString, varg[1].VAnsiString, varg[2].VAnsiString] );
        end
      else
      begin
        writeln('  Error! ', i);
      end;
    end;
  end;
end;
                              
//------------------------------------------------------------------------------
function fp_redisCommandArgv ( c:PredisContext; argc:longint; argv:PPchar; argvlen:Psize_t ):pointer;
begin
  writeln('argc:', argc);
  writeln('argv:', argv[0]);
  
  Result := c_redisCommandArgv(c, argc, argv, nil);
end;
  


INITIALIZATION
begin

end;


FINALIZATION
begin

end;


END.


(*******************************************************************************

program __fphiredis;
{$MODE OBJFPC}


uses 
  utnhiredis;           


var
  context:PRedisContext;
  reply:PRedisReply;
  s:ansistring='zwei';
begin

  context := fp_redisconnect('127.0.0.1', 6379);
  if ( context = nil ) or ( context.err <> 0 ) then
  begin
    writeln('Error connecting to redis : ', context.errstr);
    exit;
  end;

  // Set stuff
  reply := fp_redisCommand(context, 'SET A "plüs eins"', []);
  writeln('Reply = ', reply^.str);
  
  reply := fp_redisCommand(context, 'SET %s "%s"', [ansistring('B'), s]);
  writeln('Reply = ', reply^.str);

  reply := fp_redisCommand(context, 'SET C "%s"', [ansistring('das könnte ein test sein')]);
  writeln('Reply = ', reply^.str);

  // Get stuff back
  reply := fp_redisCommand(context, 'GET A',[]);
  writeln('A = ', reply^.str);

  reply := fp_redisCommand(context, 'GET B',[]);
  writeln('B = ', reply^.str);

  reply := fp_redisCommand(context, 'GET C',[]);
  writeln('C = ', reply^.str);

end; 

*******************************************************************************)












