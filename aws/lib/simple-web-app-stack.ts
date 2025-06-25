import * as cdk from 'aws-cdk-lib';
import * as ec2 from 'aws-cdk-lib/aws-ec2';

import { Construct } from 'constructs';

export class SimpleWebAppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const vpc = new ec2.Vpc(this, 'SimpleWebAppVPC', {
      maxAzs: 2,
      cidr: '10.0.0.0/16',
      subnetConfiguration: [
        {
          cidrMask: 24,
          name: 'Public',
          subnetType: ec2.SubnetType.PUBLIC,
        }
      ],
      // NATゲートウェイは使用しない
      natGateways: 0,
    });

    const webServerSG = new ec2.SecurityGroup(this, 'WebServerSecurityGroup', {
      vpc,
      description: 'Security group for React web server',
      allowAllOutbound: true,
    });

    // HTTP (80), HTTPS (443), SSH (22), React (3000) のアクセスを許可
    webServerSG.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(80), 'HTTP access');
    webServerSG.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'HTTPS access');
    webServerSG.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(22), 'SSH access');
    webServerSG.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(3000), 'React dev server');

    const apiServerSG = new ec2.SecurityGroup(this, 'APIServerSecurityGroup', {
      vpc,
      description: 'Security group for Node.js API server',
      allowAllOutbound: true,
    });

    // SSH (22), API (3001) のアクセスを許可
    apiServerSG.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(22), 'SSH access');
    apiServerSG.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(3001), 'Node.js API server');

    // WebサーバーからのAPIアクセスを許可
    apiServerSG.addIngressRule(webServerSG, ec2.Port.tcp(3001), 'Access from web server');

    const keyPair = new ec2.KeyPair(this, 'WebAppKeyPair', {
      keyPairName: 'simple-web-app-keypair',
    });

    // Webサーバー用のUserData（Amazon Linux 2023版）
    const webUserData = ec2.UserData.forLinux({
      shebang: '#!/bin/bash -xe'
    });
    webUserData.addCommands(
      'dnf update -y',
      'dnf install -y nodejs npm git',
      
      // Node.jsとnpmのインストール確認
      'node --version',
      'npm --version',
      
      // ディレクトリ作成
      'mkdir -p /home/ec2-user/frontend',
      'chown ec2-user:ec2-user /home/ec2-user/frontend',
      
      'echo "=== Web server setup completed at $(date) ===" >> /var/log/userdata.log',
      'echo "Node.js version: $(node --version)" >> /var/log/userdata.log',
      'echo "npm version: $(npm --version)" >> /var/log/userdata.log',
      'echo "Setup status: SUCCESS" >> /var/log/userdata.log'
    );

    // APIサーバー用のUserData（Amazon Linux 2023版）
    const apiUserData = ec2.UserData.forLinux({
      shebang: '#!/bin/bash -xe'
    });
    apiUserData.addCommands(
      'dnf update -y',
      'dnf install -y nodejs npm git',
      
      // Node.jsとnpmのインストール確認
      'node --version',
      'npm --version',
      
      // pm2をグローバルインストール
      'npm install -g pm2',
      'pm2 --version',
      
      // ディレクトリ作成
      'mkdir -p /home/ec2-user/backend',
      'chown ec2-user:ec2-user /home/ec2-user/backend',
      
      'echo "=== API server setup completed at $(date) ===" >> /var/log/userdata.log',
      'echo "Node.js version: $(node --version)" >> /var/log/userdata.log',
      'echo "npm version: $(npm --version)" >> /var/log/userdata.log',
      'echo "pm2 version: $(pm2 --version)" >> /var/log/userdata.log',
      'echo "Setup status: SUCCESS" >> /var/log/userdata.log'
    );

    const webServerInstance = new ec2.Instance(this, 'WebServerInstance', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      machineImage: ec2.MachineImage.latestAmazonLinux2023(),
      securityGroup: webServerSG,
      keyPair: keyPair,
      userData: webUserData,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    const apiServerInstance = new ec2.Instance(this, 'APIServerInstance', {
      vpc,
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.T3, ec2.InstanceSize.MICRO),
      machineImage: ec2.MachineImage.latestAmazonLinux2023(),
      securityGroup: apiServerSG,
      keyPair: keyPair,
      userData: apiUserData,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
    });

    const webServerEIP = new ec2.CfnEIP(this, 'WebServerEIP', {
      instanceId: webServerInstance.instanceId,
    });

    const apiServerEIP = new ec2.CfnEIP(this, 'APIServerEIP', {
      instanceId: apiServerInstance.instanceId,
    });

    new cdk.CfnOutput(this, 'WebServerInstanceId', {
      value: webServerInstance.instanceId,
      description: 'Web Server EC2 Instance ID',
    });

    new cdk.CfnOutput(this, 'APIServerInstanceId', {
      value: apiServerInstance.instanceId,
      description: 'API Server EC2 Instance ID',
    });

    new cdk.CfnOutput(this, 'WebServerPublicIP', {
      value: webServerEIP.ref,
      description: 'Web Server Public IP Address',
    });

    new cdk.CfnOutput(this, 'APIServerPublicIP', {
      value: apiServerEIP.ref,
      description: 'API Server Public IP Address',
    });

    new cdk.CfnOutput(this, 'WebServerSSHCommand', {
      value: `ssh -i ~/.ssh/${keyPair.keyPairName}.pem ec2-user@${webServerEIP.ref}`,
      description: 'SSH Command for Web Server',
    });

    new cdk.CfnOutput(this, 'APIServerSSHCommand', {
      value: `ssh -i ~/.ssh/${keyPair.keyPairName}.pem ec2-user@${apiServerEIP.ref}`,
      description: 'SSH Command for API Server',
    });

    new cdk.CfnOutput(this, 'ReactAppURL', {
      value: `http://${webServerEIP.ref}:3000`,
      description: 'React Application URL',
    });

    new cdk.CfnOutput(this, 'APIURL', {
      value: `http://${apiServerEIP.ref}:3001`,
      description: 'API Server URL',
    });

    new cdk.CfnOutput(this, 'APITestURL', {
      value: `http://${apiServerEIP.ref}:3001/api/data`,
      description: 'API Test Endpoint',
    });
  }
}
