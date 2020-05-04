```mermaid
stateDiagram
	WAIT --> ENQ : cond1
	WAIT --> DEQ : cond2
	%%c
```

cond1 = en_in && count<16

cond2 = en_out && count>0