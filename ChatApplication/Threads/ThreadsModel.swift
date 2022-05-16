//
//  ThreadsModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import FanapPodChatSDK

struct ThreadsModel {
    
    private (set) var count                                     = 15
    private (set) var offset                                    = 0
    private (set) var totalCount                                = 0
    private (set) var threads :[Conversation]                   = []
    private (set) var isViewDisplaying                          = false
    private (set) var threadsTyping:[SystemEventModel]          = []
    private (set) var callsToJoin:[Call]                        = []
    
    func hasNext()->Bool{
        return threads.count < totalCount
    }
    
    mutating func preparePaginiation(){
        offset = count + offset
    }
    
    mutating func setContentCount(totalCount:Int){
        self.totalCount = totalCount
    }
    
    mutating func setThreads(threads:[Conversation]){
        self.threads = threads
        sort()
    }
    
    mutating func appendThreads(threads:[Conversation]){
        //remove older data to prevent duplicate on view
        self.threads.removeAll(where: { cashedThread in threads.contains(where: {cashedThread.id == $0.id }) })
        self.threads.append(contentsOf: threads)
        sort()
    }
    
    mutating func sort(){
        self.threads.sort(by: {$0.time ?? 0 > $1.time ?? 0})
        self.threads.sort(by: {$0.pin == true && $1.pin == false})
    }
    
    mutating func clear(){
        self.offset     = 0
        self.count      = 15
        self.totalCount = 0
        self.threads    = []
    }
	
	mutating func pinThread(_ thread:Conversation){
		threads.first(where: {$0.id == thread.id})?.pin = true
	}
    
	mutating func unpinThread(_ thread:Conversation){
		threads.first(where: {$0.id == thread.id})?.pin = false
	}
    
    mutating func muteUnMuteThread(_ threadId:Int?, isMute:Bool){
        if let threadId = threadId , let index = threads.firstIndex(where: {$0.id == threadId}) {
            threads[index].mute = isMute
        }        
    }
    
    mutating func removeThread(_ thread:Conversation){
        guard let index = threads.firstIndex(of: thread) else{return}
        threads.remove(at: index)
    }
    
    mutating func setViewAppear(appear:Bool){
        isViewDisplaying = appear
    }
    
    mutating func addNewMessageToThread(_ event:MessageEventModel){
        if let index = threads.firstIndex(where: {$0.id == event.message?.conversation?.id}){
            let thread = threads[index]
            thread.unreadCount = event.message?.conversation?.unreadCount ?? 1
            thread.lastMessageVO = event.message
            thread.lastMessage   = event.message?.message
        }
    }
    
    mutating func addTypingThread(_ event:SystemEventModel)->Bool{
        if threadsTyping.contains(where: {$0.threadId == event.threadId}) == false{
            threadsTyping.append(event)
            return true
        }else{
            return false
        }
    }
    
    mutating func removeTypingThread(_ event:SystemEventModel){
        if let index = threadsTyping.firstIndex(where: { $0.threadId == event.threadId }){
            threadsTyping.remove(at: index)
        }
    }
    
    mutating func addActiveCalls(_ calls:[Call]){
        callsToJoin.append(contentsOf: calls)
    }
    
}

extension ThreadsModel{
    
    mutating func setupPreview(){
        appendThreads(threads: MockData.generateThreads())
    }
}
