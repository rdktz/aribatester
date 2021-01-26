# ariba WS tester

Very simple tester for web services: slurp the input and sleep for the number of seconds specified in the GET param

Running:

perl aribatester.pl daemon -l http://127.0.0.1:12100

or with nohup

$ nohup perl aribatester.pl daemon -l http://127.0.0.1:12100 2>&1 | tee -a ~/domains/aribatest.xyz.net/logs/nohup.out
[2021-01-26 13:20:26.75877] [96883] [info] Listening at "http://127.0.0.1:12100"
Server available at http://127.0.0.1:12100




