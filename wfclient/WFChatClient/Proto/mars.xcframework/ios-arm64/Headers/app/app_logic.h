// Tencent is pleased to support the open source community by making Mars available.
// Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.

// Licensed under the MIT License (the "License"); you may not use this file except in 
// compliance with the License. You may obtain a copy of the License at
// http://opensource.org/licenses/MIT

// Unless required by applicable law or agreed to in writing, software distributed under the License is
// distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions and
// limitations under the License.

/*
 * app_logic.h
 *
 *  Created on: 2016/3/3
 *      Author: caoshaokun
 */

#ifndef APPCOMM_INTERFACE_APPCOMM_LOGIC_H_
#define APPCOMM_INTERFACE_APPCOMM_LOGIC_H_

#include <string>
#include <vector>

#include "app/app.h"
#include "comm/comm_data.h"

class AutoBuffer;

namespace mars {
namespace app {

	class Callback {
	public:
		virtual ~Callback() {};
        
        virtual bool GetProxyInfo(const std::string& _host, mars::comm::ProxyInfo& _proxy_info);

        virtual std::string GetAppFilePath() = 0;
        
		virtual AccountInfo GetAccountInfo() = 0;

		virtual unsigned int GetClientVersion() = 0;

		virtual DeviceInfo GetDeviceInfo() = 0;

		// 返回当前平台的系统根证书，用于 TLS 证书链校验。
		// 每个元素是一张证书的原始字节，PEM 或 DER 均可。
		// 默认实现返回空列表，表示该平台不通过回调提供根证书。
		// 目前 Android/Windows/Linux 已在 C++ 层内置系统 CA 查找，无需实现；
		// iOS/macOS/Harmony 等平台由宿主实现本方法。
		virtual void GetRootCerts(std::vector<std::string>& _certs);

		// 平台是否具备"用自己的信任库校验证书链"的能力（如 iOS/macOS 的 Security.framework）。
		// 默认 false。返回 true 时，协议栈会在校验开启时把链校验委托给 VerifyServerCerts，
		// 并且即使拿不到任何根证书也保持校验开启（因为平台自己能判）。
		virtual bool CanVerifyServerCerts();

		// 用平台信任库校验证书链（含域名校验）。
		// _der_chain：服务端证书链，leaf 在首位，每项为 DER 原始字节；
		// _host：拨号使用的主机名（IP 字面量时平台可按自己策略处理）。
		// 返回值：1 = 可信；0 = 不可信；-1 = 平台不处理，交回协议栈用自带根证书校验。
		virtual int VerifyServerCerts(const std::vector<std::string>& _der_chain, const std::string& _host);

	};
	void SetCallback(Callback* const callback);
}}


#endif /* APPCOMM_INTERFACE_APPCOMM_LOGIC_H_ */
