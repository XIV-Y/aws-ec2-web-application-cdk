#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';

import { SimpleWebAppStack } from '../lib/simple-web-app-stack';

const app = new cdk.App();

new SimpleWebAppStack(app, 'SimpleWebAppStack', {});
