#!/bin/bash

SOURCE_FILE="clickme.yaml"
TARGET_FILE="config.yaml"
HASH_FILE="clickme.hash"
TEMP_FILE="temp.yaml"

# 检查 source.yaml 是否存在
if [ ! -f "${SOURCE_FILE}" ]; then
  echo "源文件 ${SOURCE_FILE} 不存在"
  exit 1
fi

# 检查 target.yaml 是否存在
if [ ! -f "${TARGET_FILE}" ]; then
  echo "目标文件 ${TARGET_FILE} 不存在"
  exit 1
fi

# 计算源文件的哈希值
SOURCE_HASH=$(sha256sum "${SOURCE_FILE}" | awk '{print $1}')

# 读取上次的哈希值
if [ -f "${HASH_FILE}" ]; then
  LAST_SOURCE_HASH=$(cat "${HASH_FILE}")
else
  LAST_SOURCE_HASH=""
fi

# 如果哈希值不同，表示文件有变动
if [ "${SOURCE_HASH}" != "${LAST_SOURCE_HASH}" ]; then
  echo "检测到源文件 ${SOURCE_FILE} 有变动，开始覆写目标文件 ${TARGET_FILE}"

  # 使用 yq 将源文件的内容覆写到目标文件
  yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "${TARGET_FILE}" "${SOURCE_FILE}" > "${TEMP_FILE}"
  mv "${TEMP_FILE}" "${TARGET_FILE}"

  # 更新哈希值
  echo "${SOURCE_HASH}" > "${HASH_FILE}"

  echo "覆写完成"
else
  echo "源文件 ${SOURCE_FILE} 没有变动"
fi