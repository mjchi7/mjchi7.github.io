---
title: "Https for Developer"
date: 2022-07-12T18:12:53+08:00
draft: true
tags: ["ssl", "tls", "https", "public-key-certificate"]
---

Structure
1. What is HTTPS
1.1. What exactly make it "Secure"?
1.2. Network packets of HTTP v.s. HTTPS (wireshark capture)
2. Public Key Certificate
2.1. X.509 Standard. What fields do they contain
3. Chain of Trust - it's certificate all the way down
3.1. Chain of Trust 
3.2. Certificate Authority
3.3. Root Certificate and Intermediate Certificate
- What's stopping us from creating own root CA? Nothing! Except no devices are gonna trust you.
4. Setting up Locally
- Why? To test out HTTPS locally without going through external CA. Also sometimes URL are mocked up and is not accessible for challenges (link to Letsencrypt)
4.1. Self Signed Root Certificate Authority
- One problem: we can't make browser "trust" it because self-signed root CA is not intended for server authentication - merely to sign other certificate
4.2. Signing a CSR with Own Root CA
- Create CSR
- Instead of sending it to external CA, we sign it using our own root CA
- Add root CA to browser's trusted list
- Now no more error display
