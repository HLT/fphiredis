program fphiredis_test;
{$MODE OBJFPC}
{$LONGSTRINGS ON}
uses 
  utnhiredis;

var
  context:PRedisContext;
  reply:PRedisReply;
  s:ansistring='zwei';
begin

  context := fp_redisconnect('127.0.0.1', 6379);
  if (context = nil ) or ( context^.err <> 0 ) then
  begin
    writeln('Error connecting to redis server : ', context^.errstr);
    exit;
  end;

  reply := fp_redisCommand(context, 'SET A "plüs öne"', []);
  writeln('Reply = ', reply^.str);

  reply := fp_redisCommand(context, 'SET %s "%s"', [ansistring('B'), s]);
  writeln('Reply = ', reply^.str);

  reply := fp_redisCommand(context, 'SET C "%s"', [ansistring('das könnte ein test sein')]);
  writeln('Reply = ', reply^.str);


  reply := fp_redisCommand(context, 'GET A',[]);
  writeln('A=', reply^.str);

  reply := fp_redisCommand(context, 'GET B',[]);
  writeln('B=', reply^.str);

  reply := fp_redisCommand(context, 'GET C',[]);
  writeln('C = ', reply^.str);

end.
