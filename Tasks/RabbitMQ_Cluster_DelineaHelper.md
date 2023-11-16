Delinea - Create a RabbitMQ Cluster of nodes. (Non-TLS)

* Remove & Install RabbitMQ on the computer
  * Open the RabbitMQ Helper Powershell window:
Enable-RabbitMQManagement
  * We will remove RabbitMQ and then re-install it
Uninstall-rabbitMQ
Get-rabbitmqinstaller -usedelineamirror:$false
Install-rabbitmq
*       Configure Single-host RabbitMQ by using: Start | RabbitMQ Server | RabbitMQ Command Prompt
  * Rabbitmq-plugins.bat enable rabbitmq_management
*       Enter the RabbitMQ Portal
  * Guest / guest
  * Admin tab
  * Go to Secret Server tab:
  * Distributed Engine – Create a Site Connector (specify the vIP in the Hostname field).
  * VIEW CREDENTIALS – copy and use in the RabbitMQ
  * Paste in Username & Password (again for confirm) and then Add User.
  * Click on the username to set permissions
Under Permissions & Current Permissions is a gray button labelled Set Permissions.
Press [Set Permission] button to set
*       Virtual Host:  /
*       Configure regexp:  .*
*       Write regexp:  .*
*       Read regexp:  .*
*       In Secret Server – We can see if the Site returns information from Rabbit
  * Version number – 3.11.2.  We can communicate and receive back information from the RabbitMQ.
  * Site Connector is a Username / Password 
*       Back in the RabbitMQ Portal Page
  * Connections Tab – see a bunch of connections.
  * Queues – Will come when the engine is connected.
  * Admin – Users.  Click on Guest user.
  * Bottom – change the password.  Update the user and change the password.
*       Now, Make the individual RabbitMQs a cluster from the RabbitMQ Command Prompt (sbin dir).
  * They want to have very low latency, and quick communication between them. Don’t have them in different geographic locations.
  * If a node is too slow, the cluster will reject the slow node from the cluster.
*       Join RabbitMQ Nodes 2 & 3 into the ‘Cluster’ of Node 1.
  * RabbitMQ command to join a cluster from Nodes 2 & 3, to join Node 1 Cluster:
Rabbitmqctl.bat
Rabbitmqctl.bat stop_app
Notice it will say something like ‘stopping rabbit application on node rabbit@Win-SS-Rmq2’
*       It should say Rabbit@<HOSTNAME>.  So we will use the Node1 HOSTNAME (HOSTNAME IN CAPS) in the join-command:
*       Verify all nodes have the same Erlang Cookie ….
Rabbitmqctl.bat join_cluster rabbit@<Node1 Hostname> 
Rabbitmqctl.bat start_app
Will have to do this for the upgrade of Rabbit in the future.
Now, in the RabbitMQ of the Overview tab, shows 3 nodes.
  * On nodes 2 & 3, stop_app.  Make sure we know which is being connected to.
*       Download the Distributed Engine installer.
  * Internal Site Connector – change from internally hosted bus -> RabbitMQ Service.
  * In Internal Site connector – click on Audit tab, and visualize the service has restarted.
  * Download the engine installer (Distributed Engine -> Add Engine).
  * Run this from the 2 DE machines.
  * Processing Location for LOCAL from Web App -> Distributed Engine
  * Disable CredSSP Authentication for WinRM.
  * This can be activated later if needed for CredSSP.
  * Use the ‘Assign & Activate Engines’ for both DEs in site LOCAL.
  * Validate Connectivity in the upper right – this is a round-trip drop-off and pickup from the DE.
*       Go to any single Rabbit Node / RabbitMQ Command Prompt (sbin dir).
  * Stop the other 2 RabbitMQ Nodes with stop_app
  * rabbitmqctl.BAT set_policy "cluster-delinea-ss" "^delinea-ss:" "{""ha-sync-mode"":""automatic"", ""ha-mode"":""all"", ""ha-sync-batch-size"":400}" --priority 10 --apply-to queues
  * rabbitmqctl.BAT set_policy "cluster-delinea-ss-engine-response" "^delinea-ss-engine-response:" "{""ha-sync-mode"":""automatic"", ""ha-mode"":""all"", ""ha-sync-batch-size"":400}" --priority 10 --apply-to queues
  * rabbitmqctl.BAT set_policy "cluster-delinea-ss-sessionrec" "^delinea-sessionrec:" "{""ha-sync-mode"":""automatic"", ""ha-mode"":""all"", ""ha-sync-batch-size"":400}" --priority 10 --apply-to queues
  * rabbitmqctl.BAT set_policy "cluster-delinea-Local" "^Local:" "{""ha-sync-mode"":""automatic"", ""ha-mode"":""all"", ""ha-sync-batch-size"":400}" --priority 10 --apply-to queues
  * The above only need to be run from any single Rabbit.
  * Start up the other 2 Rabbit Nodes. (With the Start_app command)
  * Should now see queues in the RabbitMQ Web Portal
*       From Secret Server, press Validate for the Distributed Engine.  
  * From RabbitMQ Web Portal, under Overview, should see data being sent in the Message Rates.
*       Upgrade of rabbit – update the 1st node, point the vIP at it, then upgrade the 2 remaining nodes, and then add them to the cluster again.
