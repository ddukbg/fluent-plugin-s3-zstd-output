
---

# Korean / [English](#english-version)

# Fluentd S3 출력 플러그인 (Zstandard 압축 지원)

**주의:** 저는 Ruby 전문가가 아니므로 일부 내용이 정확하지 않을 수 있습니다. 그리고 아직 테스트 단계이므로 운영환경에 사용하면 안됩니다!

---

## 목차

- [소개](#소개)
- [사전 준비](#사전-준비)
- [Gem 빌드하기](#gem-빌드하기)
  - [1. 플러그인 저장소 클론하기](#1-플러그인-저장소-클론하기)
  - [2. `.gemspec` 파일 확인](#2-gemspec-파일-확인)
  - [3. Gem 빌드하기](#3-gem-빌드하기)
- [Gem 설치하기](#gem-설치하기)
  - [1. 빌드한 Gem 로컬에 설치하기](#1-빌드한-gem-로컬에-설치하기)
  - [2. 설치 확인](#2-설치-확인)
- [Fluentd 구성](#fluentd-구성)
- [테스트 데이터 전송](#테스트-데이터-전송)
  - [1. 단순 로그 메시지 전송](#1-단순-로그-메시지-전송)
  - [2. 스택 트레이스를 포함한 에러 로그](#2-스택-트레이스를-포함한-에러-로그)
  - [3. 멀티라인 JSON 로그](#3-멀티라인-json-로그)
  - [4. 특수 문자와 유니코드가 포함된 로그](#4-특수-문자와-유니코드가-포함된-로그)
- [데이터 확인 방법](#데이터-확인-방법)
  - [1. S3에서 `.zst` 파일 다운로드](#1-s3에서-zst-파일-다운로드)
  - [2. `.zst` 파일 압축 해제](#2-zst-파일-압축-해제)
  - [3. 로그 확인](#3-로그-확인)
- [결론](#결론)
- [참고 자료](#참고-자료)

---

## 소개

`fluent-plugin-s3-zstd-output`는 Fluentd가 Amazon S3로 로그를 출력할 때 **Zstandard (zstd) 압축**을 지원하도록 해주는 커스텀 플러그인입니다. Zstandard는 기존의 Gzip보다 빠른 압축 및 해제 속도와 더 나은 압축률을 제공합니다.

---

## 사전 준비

- **Ruby**: 버전 2.7 이상 권장
- **Fluentd**: 시스템에 설치되어 있어야 합니다.
- **Bundler**: Ruby gem 관리 도구
- **AWS CLI**: Amazon S3와 상호 작용하기 위해 필요합니다.
- **Zstandard (zstd)**: `.zst` 파일을 해제하기 위해 시스템에 설치되어 있어야 합니다.

---

## Gem 빌드하기

### 1. 플러그인 저장소 클론하기

`fluent-plugin-s3-zstd-output` 플러그인 저장소를 클론합니다:

```bash
git clone https://github.com/yourusername/fluent-plugin-s3-zstd-output.git
cd fluent-plugin-s3-zstd-output
```

### 2. `.gemspec` 파일 확인

`.gemspec` 파일(`fluent-plugin-s3.gemspec`)이 존재하며, 비ASCII 문자가 포함되어 있지 않은지 확인합니다. 파일은 다음과 유사해야 합니다:

```ruby
# -*- encoding: utf-8 -*-
Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-s3'
  spec.version       = '1.7.2'
  spec.summary       = 'Zstandard 압축 지원을 위한 Fluentd S3 출력 플러그인'
  spec.description   = '이 플러그인은 Fluentd S3 출력 플러그인에 Zstandard 압축을 지원합니다.'
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']
  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.homepage      = 'https://github.com/yourusername/fluent-plugin-s3-zstd-output'
  spec.license       = 'Apache-2.0'

  spec.add_runtime_dependency 'fluentd', '>= 1.0.0'
  spec.add_runtime_dependency 'zstd-ruby'
end
```

### 3. Gem 빌드하기

다음 명령어를 실행하여 gem을 빌드합니다:

```bash
gem build fluent-plugin-s3.gemspec
```

이렇게 하면 `fluent-plugin-s3-1.7.2.gem`과 같은 `.gem` 파일이 생성됩니다.

---

## Gem 설치하기

### 1. 빌드한 Gem 로컬에 설치하기

다음 명령어를 사용하여 gem을 설치합니다:

```bash
gem install ./fluent-plugin-s3-1.7.2.gem
```

### 2. 설치 확인

설치된 gem 목록을 확인하여 플러그인이 설치되었는지 확인합니다:

```bash
gem list fluent-plugin-s3
```

`fluent-plugin-s3 (1.7.2)`가 표시되어야 합니다.

---

## Fluentd 구성

`fluent.conf` 파일을 편집하여 Fluentd가 Amazon S3로 로그를 출력할 때 `zstd` 압축을 사용하도록 설정합니다.

```conf
<source>
  @type forward
  @id input
  @label @mainstream
</source>

<label @mainstream>
  <match **>
    @type s3
    s3_bucket your-s3-bucket-name
    s3_region your-s3-bucket-region
    path logs/
    store_as zstd
    <format>
      @type json
    </format>
    <buffer>
      @type memory
      flush_interval 5s
    </buffer>
  </match>
</label>
```

**주의사항:**

- `your-s3-bucket-name`을 실제 S3 버킷 이름으로 변경하세요.
- `your-s3-bucket-region`을 AWS 리전 코드로 변경하세요 (예: 서울 리전은 `ap-northeast-2`).
- AWS 자격 증명이 올바르게 구성되었는지 확인하세요 (환경 변수, AWS CLI 설정 파일 또는 IAM 역할을 통해).
- `flush_interval`은 로그를 S3로 얼마나 자주 플러시할지 결정합니다. 필요에 따라 조정하세요.

---

## 테스트 데이터 전송

`fluent-cat` 명령어를 사용하여 Fluentd로 테스트 로그를 전송할 수 있습니다. 아래는 중요한 4가지 예시입니다:

### 1. 단순 로그 메시지 전송

```bash
echo '{"message": "단순한 로그 메시지입니다.", "level": "INFO", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'"}' | fluent-cat app.log
```

### 2. 스택 트레이스를 포함한 에러 로그

```bash
echo '{"message": "예외가 발생했습니다.", "level": "ERROR", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'", "error": "NullPointerException", "stacktrace": "Exception in thread \"main\" java.lang.NullPointerException\n\tat com.example.Main.main(Main.java:14)"}' | fluent-cat app.log
```

### 3. 멀티라인 JSON 로그

```bash
echo '{"message": "처리 단계 진행 중", "level": "INFO", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'", "steps": {"step1": "완료", "step2": "완료", "step3": "완료"}}' | fluent-cat app.log
```

### 4. 특수 문자와 유니코드가 포함된 로그

```bash
echo '{"message": "사용자 피드백 수신 😊", "level": "INFO", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'", "feedback": "앱이 정말 좋아요! 👍"}' | fluent-cat app.log
```

---

## 데이터 확인 방법

### 1. S3에서 `.zst` 파일 다운로드

AWS CLI를 사용하여 S3에서 로그 파일을 확인하고 다운로드합니다:

```bash
# S3 버킷의 파일 목록 확인
aws s3 ls s3://your-s3-bucket-name/logs/

# 특정 로그 파일 다운로드
aws s3 cp s3://your-s3-bucket-name/logs/your_log_file.zst ./
```

### 2. `.zst` 파일 압축 해제

Zstandard가 설치되어 있어야 합니다. 다음 명령어를 실행합니다:

```bash
zstd -d your_log_file.zst
```

이렇게 하면 `.zst` 확장자가 없는 압축 해제된 파일이 생성됩니다.

### 3. 로그 확인

텍스트 편집기나 `cat` 명령어를 사용하여 로그를 확인할 수 있습니다:

```bash
cat your_log_file
```

JSON 형식의 로그를 더 잘 읽으려면 `jq`를 사용할 수 있습니다:

```bash
cat your_log_file | jq
```

---

## 결론

이 가이드를 따라 다음을 수행했습니다:

- `fluent-plugin-s3-zstd-output` gem을 빌드하고 설치했습니다.
- Fluentd를 구성하여 Amazon S3로 로그를 출력할 때 Zstandard 압축을 사용하도록 설정했습니다.
- 테스트 데이터를 Fluentd로 전송하여 설정을 확인했습니다.
- S3에서 압축된 로그 데이터를 다운로드하고 확인했습니다.

이 설정을 통해 S3에 로그를 효율적으로 저장할 수 있으며, 향상된 압축을 통해 저장 공간을 절약하고 비용을 줄일 수 있습니다.

---

## 참고 자료

- [Fluentd 공식 웹사이트](https://www.fluentd.org/)
- [Fluentd S3 플러그인 문서](https://docs.fluentd.org/output/s3)
- [Zstandard 압축](https://facebook.github.io/zstd/)
- [AWS CLI 문서](https://docs.aws.amazon.com/ko_kr/cli/latest/userguide/cli-chap-welcome.html)

---

질문이나 추가 도움이 필요하시면 언제든지 문의해 주세요.

---

# English Version

[Korean](#fluentd-s3-출력-플러그인-zstandard-압축-지원) / English

# Fluentd S3 Output Plugin with Zstandard Compression

**Note:** I am not a Ruby expert, so some parts may not work as expected.

---

## Table of Contents

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Building the Gem](#building-the-gem)
  - [1. Clone the Plugin Repository](#1-clone-the-plugin-repository)
  - [2. Verify the `.gemspec` File](#2-verify-the-gemspec-file)
  - [3. Build the Gem](#3-build-the-gem)
- [Installing the Gem](#installing-the-gem)
  - [1. Install the Built Gem Locally](#1-install-the-built-gem-locally)
  - [2. Verify the Installation](#2-verify-the-installation)
- [Configuring Fluentd](#configuring-fluentd)
- [Sending Test Data](#sending-test-data)
  - [1. Simple Log Message](#1-simple-log-message)
  - [2. Error Log with Stack Trace](#2-error-log-with-stack-trace)
  - [3. Multiline JSON Log](#3-multiline-json-log)
  - [4. Log with Special Characters and Unicode](#4-log-with-special-characters-and-unicode)
- [Viewing the Data](#viewing-the-data)
  - [1. Download the `.zst` File from S3](#1-download-the-zst-file-from-s3)
  - [2. Decompress the `.zst` File](#2-decompress-the-zst-file)
  - [3. View the Logs](#3-view-the-logs)
- [Conclusion](#conclusion)
- [References](#references)

---

## Introduction

The `fluent-plugin-s3-zstd-output` is a custom Fluentd plugin that enables support for Zstandard (zstd) compression when outputting logs to Amazon S3. Zstandard offers faster compression and decompression speeds with better compression ratios compared to traditional methods like Gzip.

---

## Prerequisites

- **Ruby**: Version 2.7 or higher recommended.
- **Fluentd**: Installed on your system.
- **Bundler**: Ruby gem manager.
- **AWS CLI**: For interacting with Amazon S3.
- **Zstandard (zstd)**: Installed on your system to decompress `.zst` files.

---

## Building the Gem

### 1. Clone the Plugin Repository

Clone the repository containing the `fluent-plugin-s3-zstd-output` plugin:

```bash
git clone https://github.com/yourusername/fluent-plugin-s3-zstd-output.git
cd fluent-plugin-s3-zstd-output
```

### 2. Verify the `.gemspec` File

Ensure the `fluent-plugin-s3.gemspec` file is present and contains no non-ASCII characters. It should look like this:

```ruby
# -*- encoding: utf-8 -*-
Gem::Specification.new do |spec|
  spec.name          = 'fluent-plugin-s3'
  spec.version       = '1.7.2'
  spec.summary       = 'Fluentd plugin to output logs to Amazon S3 with Zstandard compression support'
  spec.description   = 'This plugin extends the Fluentd S3 output plugin to support Zstandard compression.'
  spec.authors       = ['Your Name']
  spec.email         = ['your.email@example.com']
  spec.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  spec.homepage      = 'https://github.com/yourusername/fluent-plugin-s3-zstd-output'
  spec.license       = 'Apache-2.0'

  spec.add_runtime_dependency 'fluentd', '>= 1.0.0'
  spec.add_runtime_dependency 'zstd-ruby'
end
```

### 3. Build the Gem

Run the following command to build the gem:

```bash
gem build fluent-plugin-s3.gemspec
```

This will generate a `.gem` file, such as `fluent-plugin-s3-1.7.2.gem`.

---

## Installing the Gem

### 1. Install the Built Gem Locally

Install the gem using:

```bash
gem install ./fluent-plugin-s3-1.7.2.gem
```

### 2. Verify the Installation

Check that the plugin is installed:

```bash
gem list fluent-plugin-s3
```

You should see `fluent-plugin-s3 (1.7.2)` listed.

---

## Configuring Fluentd

Edit your `fluent.conf` file to configure Fluentd to use Zstandard compression when outputting logs to Amazon S3.

```conf
<source>
  @type forward
  @id input
  @label @mainstream
</source>

<label @mainstream>
  <match **>
    @type s3
    s3_bucket your-s3-bucket-name
    s3_region your-s3-bucket-region
    path logs/
    store_as zstd
    <format>
      @type json
    </format>
    <buffer>
      @type memory
      flush_interval 5s
    </buffer>
  </match>
</label>
```

**Notes:**

- Replace `your-s3-bucket-name` with your actual S3 bucket name.
- Replace `your-s3-bucket-region` with your AWS region code (e.g., `ap-northeast-2` for Seoul).
- Ensure AWS credentials are correctly configured (via environment variables, AWS CLI configuration files, or IAM roles).
- Adjust `flush_interval` as needed.

---

## Sending Test Data

Use the `fluent-cat` command to send test logs to Fluentd. Here are four important examples:

### 1. Simple Log Message

```bash
echo '{"message": "This is a simple log message.", "level": "INFO", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'"}' | fluent-cat app.log
```

### 2. Error Log with Stack Trace

```bash
echo '{"message": "An exception occurred.", "level": "ERROR", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'", "error": "NullPointerException", "stacktrace": "Exception in thread \"main\" java.lang.NullPointerException\n\tat com.example.Main.main(Main.java:14)"}' | fluent-cat app.log
```

### 3. Multiline JSON Log

```bash
echo '{"message": "Processing steps in progress", "level": "INFO", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'", "steps": {"step1": "completed", "step2": "completed", "step3": "completed"}}' | fluent-cat app.log
```

### 4. Log with Special Characters and Unicode

```bash
echo '{"message": "User feedback received 😊", "level": "INFO", "timestamp": "'$(date +%Y-%m-%dT%H:%M:%S%z)'", "feedback": "Great app! 👍"}' | fluent-cat app.log
```

---

## Viewing the Data

### 1. Download the `.zst` File from S3

Use the AWS CLI to list and download the log file:

```bash
# List files in the S3 bucket
aws s3 ls s3://your-s3-bucket-name/logs/

# Download the specific log file
aws s3 cp s3://your-s3-bucket-name/logs/your_log_file.zst ./
```

### 2. Decompress the `.zst` File

Ensure Zstandard is installed, then run:

```bash
zstd -d your_log_file.zst
```

This will produce a decompressed file without the `.zst` extension.

### 3. View the Logs

Use `cat` or any text editor to view the logs:

```bash
cat your_log_file
```

For better readability with JSON logs, use `jq`:

```bash
cat your_log_file | jq
```

---

## Conclusion

By following this guide, you have:

- Built and installed the `fluent-plugin-s3-zstd-output` gem.
- Configured Fluentd to use Zstandard compression when outputting logs to Amazon S3.
- Sent test data to Fluentd to verify the setup.
- Downloaded and viewed the compressed log data from S3.

This setup allows you to efficiently store logs in S3 with improved compression, saving storage space and potentially reducing costs.

---

## References

- [Fluentd Official Website](https://www.fluentd.org/)
- [Fluentd S3 Plugin Documentation](https://docs.fluentd.org/output/s3)
- [Zstandard Compression](https://facebook.github.io/zstd/)
- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)

---

If you have any questions or need further assistance, feel free to reach out.

---
