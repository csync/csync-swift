/*
 * Copyright IBM Corporation 2016-2017
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

// MARK: Operation

class Operation : Foundation.Operation
{
	// MARK: OperationState

	enum State : Int {
		case initial
		case executing
		case finished
		/// Returns a string that represents the ReadyState value.
		var description : String {
			switch self {
			case .initial: return "Initial"
			case .executing: return "Executing"
			case .finished: return "Finished"
			}
		}
	}

	var state : State = .initial {
		willSet(newValue) {
			assert(newValue.rawValue > state.rawValue)

			if (newValue == .executing) || (state == .executing) {
				willChangeValue(forKey: "isExecuting")
			}
			if newValue == .finished {
				willChangeValue(forKey: "isFinished")
			}
		}
		didSet {
			if (state == .executing) || (oldValue == .executing) {
				didChangeValue(forKey: "isExecuting")
			}
			if state == .finished {
				didChangeValue(forKey: "isFinished")
			}
		}
	}

	var app : App
	var error : NSError?
	var request : Request?
	var timeout : DispatchTime {
		return DispatchTime.now() + Double(Int64(60 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
	}
	var timeoutBlock : DispatchWorkItem?

	// MARK: NSOperation properties

	override var isExecuting: Bool { return state == .executing }

	override var isFinished: Bool { return state == .finished }

	/* From the Apple docs:
	When you add an operation to an operation queue, the queue ignores the value of the
	asynchronous property and always calls the start method from a separate thread.
	Therefore, if you always run operations by adding them to an operation queue, there
	is no reason to make them asynchronous.
	*/
	override var isAsynchronous: Bool { return false }

	// MARK: NSOperation methods

	init(app: App)
	{
		self.app = app
		super.init()
	}

	override func start()
	{
		if self.isCancelled {
			error = error ?? err(CSError.internalError, msg:"Operation cancelled")
			finish()
			return
		}

		self.state = State.executing

		logger.trace("Start for operation \(self)")

		request = createRequest()

		if request != nil {
			send()
		} else {
			// operation failed or did not require communication to service
			finish()
		}
	}

	func send()
	{
		if self.isCancelled {
			error = error ?? err(CSError.internalError, msg:"Operation cancelled")
			finish()
			return
		}
		// swiftlint:disable:next force_cast
		if timeoutBlock != nil { timeoutBlock!.cancel() }
		timeoutBlock = DispatchWorkItem(block: {[unowned self] in
			self.handleTimeout()
		})
		// swiftlint:disable:next force_cast
		DispatchQueue.global(qos: DispatchQoS.QoSClass.utility).asyncAfter(deadline: timeout, execute: timeoutBlock!)
		app.transport.send(request!) {[weak self] (response, error) -> Void in
			if self?.timeoutBlock != nil { self?.timeoutBlock!.cancel() }
			self?.processResponse(response, error: error)
			self?.finish()
		}

	}

	func handleTimeout() {
		/* If not connected, handleConnect will attempt next send */
		if app.transport.connected {
			send()
		}
	}

	func handleConnect() {
		send()
	}

	func finish()
	{
		callCompletionHandler()
		state = State.finished
		logger.trace("Finish for operation \(self)")
	}

	// MARK: Operation abstract properties/methods

	fileprivate let logger = Logger("Operation")

	func createRequest() -> Request?
	{
		// Subclasses must override this method
		return nil
	}

	func processResponse(_ response: Response?, error: NSError?)
	{
		self.error = error ?? response!.error
	}

	func callCompletionHandler()
	{
		// Subclasses must override this method
	}
}

class PubOperation : Operation
{
	let key : Key
	var data : String?
	var aclid: String?
	var delete : Bool = false
	let cts = Int64(Date().timeIntervalSince1970*1000)
	var completionHandler : ((_ key: Key, _ error: NSError?) -> Void)?

	override var description: String{
		return "PubOperation key=\(key.key) state=\(state)"
	}

	init(key: Key)
	{
		self.key = key
		super.init(app: key.app)
	}

	override func createRequest() -> Request?
	{
		guard key.error == nil else {
			error = key.error!
			return nil
		}

		guard !key.isKeyPattern || delete == true else {
			error = err(CSError.invalidKey, msg:"Key for write may not contain wildcard characters")
			return nil
		}

		let request = Request.pub(key, data: data, delete: delete, cts: cts)
		if aclid != nil {
			request.assumeACL = aclid
		}
		return request
	}

	override func callCompletionHandler()
	{
		if let handler = completionHandler {
			DispatchQueue.main.async {
				handler(self.key, self.error)
			}
		}
	}
}

class SubOperation : Operation
{
	let key : Key
	var delete : Bool = false

	override var description: String{
		return "SubOperation key=\(key.key) state=\(state)"
	}

	init(key: Key)
	{
		self.key = key
		super.init(app: key.app)
	}

	override func createRequest() -> Request?
	{
		guard key.error == nil else {
			error = key.error!
			return nil
		}

		let request = delete ? Request.unsub(key) : Request.sub(key)
		return request
	}
}

class GetAclsOperation : Operation
{
	override var description: String{
		return "GetAclsOperation state=\(state)"
	}

	override func createRequest() -> Request?
	{
		let request = Request.getAcls()
		return request
	}

	override func processResponse(_ response: Response?, error: NSError?)
	{
		self.error = error ?? response!.error
		if let acls = response?.acls {
			self.app.acls = acls
		}
	}
}

class AdvanceOperation : Operation
{
	let key : Key
	var rvts : VTS?
	var lvts : VTS?
	var amountBack: Int = 0

	var fetchScheduled = false

	override var description: String{
		return "AdvanceOperation key=\(key.key) state=\(state)"
	}

	init(key: Key)
	{
		self.key = key
		super.init(app: key.app)
	}

	override func createRequest() -> Request?
	{
		guard key.error == nil else {
			error = key.error!
			print("************BAD KEY")
			return nil
		}

		rvts = app.vts[key.key]?.rvts
		lvts = app.vts[key.key]?.lvts

		var amount = Int.max
		objc_sync_enter(app.backListeners)
		if let backListeners = app.backListeners[key.key]{
			for key in backListeners {
				if key.outstandingBackwardsValues > 0 {
					amount = min(amount, key.outstandingBackwardsValues)
				}
			}
		}
		objc_sync_exit(app.backListeners)
		if amount == Int.max {
			amountBack = 0
		}
		else {
			amountBack = amount
		}

		if amount > 0 {
			let request = Request.advance(key, rvts: rvts, lvts: lvts, backwardLimit: amount)
			if request == nil {
				print("we messed up *****")
			}
			return request
		}
		else {
			let request = Request.advance(key, rvts: rvts)
			if request == nil {
				print("we messed up *****")
			}
			return request
		}
	}

	override func processResponse(_ response: Response?, error: NSError?)
	{
		self.error = error ?? response!.error

		guard let response = response, response.kind == .advance else {
			self.error = err(CSError.internalError, msg:"Malformed advance response")
			return
		}

		logger.trace("processResponse for operation \(self), count=\(response.vts.count)")

		app.stats.advanceOps += 1

		//Get lvtsprime and rvtsprime of response
		//If we have stuff to fetch, update lvts and rvts after fetch, otherwise update it now

		let rvtsPrime = response.maxvts ?? response.vts.max() ?? rvts ?? 0
		let lvtsPrime = response.minvts ?? response.vts.min() ?? lvts ?? rvtsPrime

		if response.vts.count > 0 {
			var dbVts : [VTS] = []
			do {
				let forwardDBVTS = try Log.vts(in: app.database, for: key, after: rvts ?? 0)
				dbVts += forwardDBVTS
			} catch let err as Any {
				logger.error("Advance:processResponse failed: \(err)")
				return
			}
			if amountBack > 0 {
				do {
					let backwardDBVTS = try Log.vts(in: app.database, for: key, before: lvts ?? VTS(Int64.max))
					dbVts += backwardDBVTS
				} catch let err as Any {
					logger.error("Advance:processResponse failed: \(err)")
					return
				}
			}

			let vtsToFetch = response.vts.filter { v in !dbVts.contains(v) }

			if vtsToFetch.count > 0 {
				app.stats.advanceItems += vtsToFetch.count
				let fetchOp = FetchOperation(key: key, vts: vtsToFetch, lvtsPrime: lvtsPrime, rvtsPrime: rvtsPrime)
				app.operationQueue.addOperation(fetchOp)
				fetchScheduled = true
			} else {
				//update both lvts and rvts
				app.vts[key.key] = (lvtsPrime, rvtsPrime)
				//TODO: deliver from db?
				
				//If we are going backwards, we may overlap with some values in the db, we should check those and update lvts/rvts accordingly
				if amountBack > 0 {
					do {
						if let vtsSet = try VTSTable.vts(in: app.database, for: key.key) {
							if let lvts = vtsSet.lvts, let rvts = vtsSet.rvts {
								if lvts < lvtsPrime && rvts < rvtsPrime {
									app.deliverValuesFromDB(for: key, between: (lvts,lvtsPrime))
								}
							}
						}
					} catch let err as Any {
						logger.error("Advance:processResponse failed: \(err)")
						return
					}
				}
				//TODO: Maybe think about error handling?
				_ = try? VTSTable.insert(app.database, value: (lvtsPrime, rvtsPrime), pattern: key.key)
			}
		} else {
			//update both lvts and rvts
			//TODO need some code to figure out what happens when LVTS and RVTS do not overlap with LVTS and rvts we have
			app.vts[key.key] = (lvtsPrime, rvtsPrime)
			//TODO: Maybe think about error handling?
			_ = try? VTSTable.insert(app.database, value: (lvtsPrime, rvtsPrime), pattern: key.key)
		}
	}

	override func finish()
	{
		// If no fetch was scheduled, schedule the next advance
		if !fetchScheduled {
			DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5 /* seconds from now */) {
				if self.app.hasListener(self.key.key) {
					let advanceOp = AdvanceOperation(key: self.key)
					self.app.operationQueue.addOperation(advanceOp)
				}
			}
		}

		super.finish()
	}
}

class FetchOperation : Operation
{
	let key : Key
	let vts : [VTS]
	let rvtsPrime : VTS
	let lvtsPrime : VTS

	override var description: String{
		return "FetchOperation key=\(key.key) state=\(state)"
	}

	init(key: Key, vts: [VTS],  lvtsPrime: VTS, rvtsPrime: VTS)
	{
		self.key = key
		self.vts = vts
		self.rvtsPrime = rvtsPrime
		self.lvtsPrime = lvtsPrime
		super.init(app: key.app)
	}

	override func createRequest() -> Request?
	{
		guard key.error == nil else {
			error = key.error!
			return nil
		}

		let request = Request.fetch(vts)
		return request
	}

	override func processResponse(_ response: Response?, error: NSError?)
	{
		self.error = error ?? response!.error

		guard let response = response, response.kind == .fetch,
			let values = response.values else {
				self.error = err(CSError.internalError, msg:"Malformed advance response")
				return
		}

		logger.trace("processResponse for operation \(self), count=\(values.count)")

		// Deliver the updates
		for value in values {
			if app.updateLatest(value) {
				app.deliverToListeners(value)
			}
		}

		// Update lvts and rvts
		//TODO: check if we need lock
		app.vts[key.key] = (lvtsPrime, rvtsPrime)
		_ = try? VTSTable.insert(app.database, value: (lvtsPrime, rvtsPrime), pattern: key.key)

	}

	override func finish()
	{
		// If the app is still listening to this key, schedule the next advance (immediately)
		if app.hasListener(key.key) {
			let advanceOp = AdvanceOperation(key: self.key)
			DispatchQueue.main.async {
				self.app.operationQueue.addOperation(advanceOp)
			}
		}

		super.finish()
	}
}
