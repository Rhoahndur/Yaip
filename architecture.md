graph TB
    subgraph "iOS App - SwiftUI"
        subgraph "Views Layer"
            AuthViews[Auth Views<br/>Login/SignUp/Profile]
            ConvListView[Conversation List View]
            ChatView[Chat View<br/>Messages/Composer]
            AIViews[AI Feature Views<br/>Summary/Actions/Search]
        end
        
        subgraph "ViewModels Layer"
            AuthVM[AuthViewModel]
            ConvListVM[ConversationListViewModel]
            ChatVM[ChatViewModel]
            AIVM[AIFeaturesViewModel]
        end
        
        subgraph "Services Layer"
            AuthSvc[AuthManager]
            MsgSvc[MessageService]
            ConvSvc[ConversationService]
            AISvc[AIService]
            MediaSvc[MediaManager]
        end
        
        subgraph "Local Storage"
            SwiftData[(SwiftData<br/>LocalMessage<br/>LocalConversation)]
        end
        
        subgraph "Managers"
            PresenceMgr[PresenceManager]
            NotifMgr[NotificationManager]
            NetworkMon[NetworkMonitor]
        end
    end
    
    subgraph "Firebase Backend"
        subgraph "Firebase Auth"
            FBAuth[Firebase Authentication<br/>Email/Password<br/>Apple Sign-In]
        end
        
        subgraph "Firestore Database"
            UsersCol[(users/)]
            ConvCol[(conversations/)]
            MsgSubCol[(messages/ subcollection)]
            DecisionsCol[(decisions/ subcollection)]
            PresenceCol[(userPresence/)]
            PriorityCol[(userPriority/)]
            CacheCol[(aiCache/)]
        end
        
        subgraph "Firebase Storage"
            Storage[(Cloud Storage<br/>Images/Media)]
        end
        
        subgraph "Firebase Cloud Messaging"
            FCM[FCM Push Notifications]
        end
        
        subgraph "Cloud Functions"
            SendNotif[sendMessageNotification<br/>Firestore Trigger]
            
            subgraph "AI Functions"
                Summarize[generateThreadSummary<br/>Callable]
                ActionItems[extractActionItems<br/>Callable]
                SearchFn[searchMessages<br/>Callable]
                PriorityFn[detectPriorityMessages<br/>Scheduled]
                DecisionFn[trackDecisions<br/>Firestore Trigger]
                ProactiveFn[detectSchedulingIntent<br/>Firestore Trigger]
                EmbedFn[embedMessage<br/>Firestore Trigger]
            end
        end
    end
    
    subgraph "External APIs"
        subgraph "Anthropic"
            Claude[Claude 3.5 Sonnet API<br/>Text Generation<br/>Tool Use]
        end
        
        subgraph "OpenAI"
            Embeddings[OpenAI Embeddings API<br/>text-embedding-3-small]
        end
        
        subgraph "Pinecone"
            VectorDB[(Pinecone Vector DB<br/>Message Embeddings<br/>Semantic Search)]
        end
    end
    
    subgraph "Apple Services"
        APNs[Apple Push Notification Service]
        EventKit[EventKit<br/>Calendar/Reminders]
    end

    %% View to ViewModel connections
    AuthViews -->|State Binding| AuthVM
    ConvListView -->|State Binding| ConvListVM
    ChatView -->|State Binding| ChatVM
    AIViews -->|State Binding| AIVM

    %% ViewModel to Service connections
    AuthVM -->|Auth Operations| AuthSvc
    ConvListVM -->|Fetch Conversations| ConvSvc
    ChatVM -->|Send/Receive Messages| MsgSvc
    ChatVM -->|Update Typing Status| PresenceMgr
    AIVM -->|AI Requests| AISvc

    %% Service to Firebase connections
    AuthSvc -->|Sign Up/Login| FBAuth
    AuthSvc -->|Create User Doc| UsersCol
    ConvSvc -->|CRUD Operations| ConvCol
    MsgSvc -->|Send Messages| MsgSubCol
    MsgSvc -->|Real-time Listener| MsgSubCol
    PresenceMgr -->|Update Status| PresenceCol
    MediaSvc -->|Upload Images| Storage

    %% Local Storage connections
    MsgSvc -.->|Cache Messages| SwiftData
    ConvSvc -.->|Cache Conversations| SwiftData
    ChatVM -.->|Read Offline Data| SwiftData

    %% AI Service to Cloud Functions
    AISvc -->|HTTPS Call| Summarize
    AISvc -->|HTTPS Call| ActionItems
    AISvc -->|HTTPS Call| SearchFn

    %% Cloud Functions to Firestore
    SendNotif -->|Triggered by| MsgSubCol
    DecisionFn -->|Triggered by| MsgSubCol
    ProactiveFn -->|Triggered by| MsgSubCol
    EmbedFn -->|Triggered by| MsgSubCol
    PriorityFn -->|Scheduled Cron| ConvCol

    %% Cloud Functions write back
    SendNotif -.->|Read User Tokens| UsersCol
    DecisionFn -.->|Write Decisions| DecisionsCol
    ProactiveFn -.->|Write Assistant Message| MsgSubCol
    PriorityFn -.->|Write Priority Data| PriorityCol

    %% AI Functions to External APIs
    Summarize -->|Generate Summary| Claude
    ActionItems -->|Extract with Tool Use| Claude
    DecisionFn -->|Detect Decisions| Claude
    ProactiveFn -->|Analyze Intent| Claude
    PriorityFn -->|Score Messages| Claude
    
    SearchFn -->|Semantic Search Query| Claude
    SearchFn -->|Get Embeddings| Embeddings
    SearchFn -->|Vector Search| VectorDB
    
    EmbedFn -->|Generate Embeddings| Embeddings
    EmbedFn -->|Store Vectors| VectorDB

    %% Caching layer
    Summarize -.->|Read/Write Cache| CacheCol
    ActionItems -.->|Read/Write Cache| CacheCol
    SearchFn -.->|Read/Write Cache| CacheCol

    %% Push Notifications flow
    SendNotif -->|Send Notification| FCM
    FCM -->|Push to Device| APNs
    APNs -->|Deliver Notification| NotifMgr
    NotifMgr -->|Handle & Navigate| ChatView

    %% Optional iOS integrations
    AIVM -.->|Add Reminders| EventKit

    %% Network monitoring
    NetworkMon -.->|Monitor Status| MsgSvc
    NetworkMon -.->|Trigger Sync| SwiftData

    %% Styling
    classDef viewStyle fill:#e1f5ff,stroke:#01579b,stroke-width:2px
    classDef vmStyle fill:#fff9c4,stroke:#f57f17,stroke-width:2px
    classDef serviceStyle fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef firebaseStyle fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef aiStyle fill:#e8f5e9,stroke:#1b5e20,stroke-width:2px
    classDef externalStyle fill:#fce4ec,stroke:#880e4f,stroke-width:2px
    classDef storageStyle fill:#e0f2f1,stroke:#004d40,stroke-width:2px

    class AuthViews,ConvListView,ChatView,AIViews viewStyle
    class AuthVM,ConvListVM,ChatVM,AIVM vmStyle
    class AuthSvc,MsgSvc,ConvSvc,AISvc,MediaSvc,PresenceMgr,NotifMgr serviceStyle
    class FBAuth,FCM,SendNotif firebaseStyle
    class Summarize,ActionItems,SearchFn,PriorityFn,DecisionFn,ProactiveFn,EmbedFn aiStyle
    class Claude,Embeddings,VectorDB,APNs,EventKit externalStyle
    class UsersCol,ConvCol,MsgSubCol,DecisionsCol,PresenceCol,PriorityCol,CacheCol,Storage,SwiftData storageStyle