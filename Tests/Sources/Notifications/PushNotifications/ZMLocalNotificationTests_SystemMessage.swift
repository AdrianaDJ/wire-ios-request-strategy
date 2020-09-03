//
// Wire
// Copyright (C) 2020 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//

import WireTesting
@testable import WireRequestStrategy

class ZMLocalNotificationTests_SystemMessage : ZMLocalNotificationTests {
    
    // MARK: - Helpers
    
    func noteForParticipantAdded(_ conversation: ZMConversation, aSender: ZMUser, otherUsers: Set<ZMUser>) -> ZMLocalNotification? {
        let event = createMemberJoinUpdateEvent(UUID.create(), conversationID: conversation.remoteIdentifier!, users: Array(otherUsers), senderID: aSender.remoteIdentifier)
        
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }

    func noteForParticipantsRemoved(_ conversation: ZMConversation, aSender: ZMUser, otherUsers: Set<ZMUser>) -> ZMLocalNotification? {
        let event = createMemberLeaveUpdateEvent(UUID.create(), conversationID: conversation.remoteIdentifier!, users: Array(otherUsers), senderID: aSender.remoteIdentifier)
        
        return ZMLocalNotification(event: event, conversation: conversation, managedObjectContext: syncMOC)
    }
    
    // MARK: - Tests
    
    func testThatItDoesNotCreateANotificationForConversationRename() {
    
        // given
        let payload = [
            "from": sender.remoteIdentifier!.transportString(),
            "conversation": groupConversation.remoteIdentifier!.transportString(),
            "time": NSDate().transportString(),
            "data": [
                "name": "New Name"
            ],
            "type": "conversation.rename"
            ] as [String: Any]
        let event = ZMUpdateEvent(fromEventStreamPayload: payload as ZMTransportData, uuid: nil)!
        
        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversation, managedObjectContext: syncMOC)
        
        // then
        XCTAssertNil(note)
    }
    
    func testThatItCreatesANotificationForParticipantAdd_Self() {

        //    "push.notification.member.join.self" = "%1$@ added you";
        //    "push.notification.member.join.self.noconversationname" = "%1$@ added you to a conversation";

        // given, when
        let note1 = noteForParticipantAdded(groupConversation, aSender: sender, otherUsers: Set(arrayLiteral: selfUser))
        let note2 = noteForParticipantAdded(groupConversationWithoutName, aSender: sender, otherUsers: Set(arrayLiteral: selfUser))
        let note3 = noteForParticipantAdded(groupConversation, aSender: sender, otherUsers: Set(arrayLiteral: selfUser, otherUser1))
        
        // then
        XCTAssertNotNil(note1)
        XCTAssertNotNil(note2)
        XCTAssertNotNil(note3)
        XCTAssertEqual(note1!.body, "Super User added you")
        XCTAssertEqual(note2!.body, "Super User added you to a conversation")
        XCTAssertEqual(note3!.body, "Super User added you")
    }
    
    func testThatItDoesNotCreateANotificationForParticipantAdd_Other() {
        XCTAssertNil(noteForParticipantAdded(groupConversation, aSender: sender, otherUsers: Set(arrayLiteral: otherUser1)))
        XCTAssertNil(noteForParticipantAdded(groupConversation, aSender: sender, otherUsers: Set(arrayLiteral: otherUser1, otherUser2)))
        XCTAssertNil(noteForParticipantAdded(groupConversationWithoutName, aSender: sender, otherUsers: Set(arrayLiteral: otherUser1)))
        XCTAssertNil(noteForParticipantAdded(groupConversationWithoutName, aSender: sender, otherUsers: Set(arrayLiteral: otherUser1, otherUser2)))
    }

    func testThatItDoesNotCreateANotificationWhenTheUserLeaves(){
        
        // given
        let event = createMemberLeaveUpdateEvent(UUID.create(), conversationID: self.groupConversation.remoteIdentifier!, users: [otherUser1], senderID: otherUser1.remoteIdentifier)
        
        // when
        let note = ZMLocalNotification(event: event, conversation: groupConversation, managedObjectContext: syncMOC)
        
        // then
        XCTAssertNil(note)
    }

    func testThatItCreatesANotificationForParticipantRemove_Self() {

        //    "push.notification.member.leave.self" = "%1$@ removed you from %2$@";
        //    "push.notification.member.leave.self.noconversationname" = "%1$@ removed you from a conversation";
        
        // given, when
        let note1 = noteForParticipantsRemoved(groupConversation, aSender: sender, otherUsers: [selfUser])
        let note2 = noteForParticipantsRemoved(groupConversationWithoutName, aSender: sender, otherUsers: [selfUser])
        
        // then
        XCTAssertNotNil(note1)
        XCTAssertNotNil(note2)
        XCTAssertEqual(note1!.body, "Super User removed you")
        XCTAssertEqual(note2!.body, "Super User removed you from a conversation")
    }
    
    func testThatItDoesNotCreateNotificationsForParticipantRemoved_Other() {
        XCTAssertNil(noteForParticipantsRemoved(groupConversation, aSender: sender, otherUsers: [otherUser1]))
        XCTAssertNil(noteForParticipantsRemoved(groupConversation, aSender: sender, otherUsers: [otherUser1, otherUser2]))
        XCTAssertNil(noteForParticipantsRemoved(groupConversationWithoutName, aSender: sender, otherUsers: [otherUser1]))
        XCTAssertNil(noteForParticipantsRemoved(groupConversationWithoutName, aSender: sender, otherUsers: [otherUser1, otherUser2]))
    }
}

