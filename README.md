## Azure Production WebServer
This sample code:  
1. Prod/Non Prod VNETs and Subnets  
2. Associated resources like interfaces, dhcp pools etc  
3. Creates Security Groups with most common inbound TCP/UDP rules  
4. Craetes NetWatcher RG explicitly since TF wont delete default ones  
Code assumes Public SSH Key is available at `~/.ssh/id_rsa.pub`
