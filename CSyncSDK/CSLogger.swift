/*
 * Copyright IBM Corporation 2016
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

enum LogLevel : Int, Comparable, CustomStringConvertible {
	case debug = 1
	case trace = 2
	case info = 3
	case warn = 4
	case error = 5
	var description : String {
		switch self {
		case .debug: return "Debug"
		case .trace: return "Trace"
		case .info: return "Info"
		case .warn: return "Warn"
		case .error: return "Error"
		}
	}
}

func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
	return lhs.rawValue < rhs.rawValue
}

// TODO: Rename and consolidate?
class CSLogger
{
	static let sharedInstance = CSLogger()

	var channelMap : [String : LogLevel] = [:]

	func debug(_ channel: String, msg: String) {
		if let lvl = channelMap[channel], lvl <= LogLevel.debug {
			print(msg)
		}
	}

	func trace(_ channel: String, msg: String) {
		if let lvl = channelMap[channel], lvl <= LogLevel.trace {
			print(msg)
		}
	}

	func info(_ channel: String, msg: String) {
		if let lvl = channelMap[channel], lvl <= LogLevel.info {
			print(msg)
		}
	}

	func warn(_ channel: String, msg: String) {
		if let lvl = channelMap[channel], lvl <= LogLevel.warn {
			print(msg)
		}
	}

	func error(_ channel: String, msg: String) {
		if let lvl = channelMap[channel], lvl <= LogLevel.error {
			print(msg)
		}
	}
}

class Logger
{
	let channel : String

	init(_ channel: String) {
		self.channel = channel
		#if DEBUG
		CSLogger.sharedInstance.channelMap[channel] = LogLevel.trace
		#else
		CSLogger.sharedInstance.channelMap[channel] = LogLevel.error
		#endif
	}

	func logLevel(_ lvl: LogLevel) {
		CSLogger.sharedInstance.channelMap[channel] = lvl
	}

	func debug(_ msg: String) {
		CSLogger.sharedInstance.debug(channel, msg: msg)
	}

	func trace(_ msg: String) {
		CSLogger.sharedInstance.trace(channel, msg: msg)
	}

	func info(_ msg: String) {
		CSLogger.sharedInstance.info(channel, msg: msg)
	}

	func warn(_ msg: String) {
		CSLogger.sharedInstance.warn(channel, msg: msg)
	}

	func error(_ msg: String) {
		CSLogger.sharedInstance.error(channel, msg: msg)
	}
}
