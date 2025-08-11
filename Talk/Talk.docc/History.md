# History

This document demonstrate how to properly fetch a history of a thread.

## Overview

There are numerous ways to fetch history messages of a thread, in which we call each one a 'Scenario'.

### Scenario 1
1- In this scenario, the user enters the conversation page for the first time and there are new unread messages in the conversation, so we have to fetch the top part with lastSeenMessageTime.

2- After data comes from the server we append and sort messages.

3- In this stage due to the array is already sorted we can add unreadBanner to the bottom of the list.

4- We disable scrolling and set isProgramaticallyScrolling to true to prevent overloading top history.

5- Then update the UI.

6- Move to the last message seen with a uniqueid.

7-  After that we set has more top properties and disable the animation of loadings for the top.

8- Fetch the bottom and new messages with lastMessageSeenTime and send it as 'fromTime'. 

9- Then append new messages and sort them.

10- After that we set has more bottom properties and disable animation of loadings for the bottom.

11- Lastly update the UI.

### Scenario 2
1- In this scenario, the user enters the conversation page for the first time and there are not any new messages and the lastMessageSeenId is equal to the last message in the thread id, and we just have to fetch the top part with lastMessageSeenTime.

2- After data comes from the server we append and sort messages.

3- At this stage, we don't have any new messages so there is no need to add a banner.

4- We disable scrolling and set isProgramaticallyScrolling to true to prevent overloading top history.

5- Then update the UI.

6- Move to the last message uniqueId in the thread.

7- After that we set has more top properties and disable the animation of loadings for the top.

### Scenario 3 and 4
1- In these scenarios, we fetch only when the user scrolls to the top or bottom of the list with the top or bottom message in the current message list in the memory.

2- Then we store the top or bottom message in the current list to scroll to later.

3- After data comes from the server we append and sort messages.

4- We disable scrolling and set isProgramaticallyScrolling to true to prevent overloading top/bottom history.

5- Then update the UI.

6- Move to the last/first message uniqueId in the thread.

7- After that we set has more top/bottom properties and disable the animation of loadings for the top/bottom.

### Scenario 5
1- In these scenarios, we fetch only when the disconnect and connect again only bottom part with last message in the current list.
2- All the stages are similar to the scenario first second and adding a new banner.

### Scenario 6
1- In these scenarios, when the user taps on a message where it is not available in the list such as pin/reply/files in detail view/search and so on, we have to clear the memory of messages and show loading in the center of the screen, also fetching the top part with the message itself.

2- All the stages are similar except we don't have to add a banner and in the last stage we have to fetch more bottom items to store them when the user scrolls down to see the messages.

>Tip: If the message already exists in the memory there will be no request to the server and move directly to the message.
