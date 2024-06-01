/*! Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  SPDX-License-Identifier: MIT-0
 */

'use strict'

// The Lambda handler
exports.handler = async (event) => {
  event.Records.forEach(function(record){
    let body = JSON.parse(record.body);
    console.log(`subject: ${body.Subject}, message: ${body.Message}`);
  });
  // console.log(JSON.stringify(event, 2, null))
}