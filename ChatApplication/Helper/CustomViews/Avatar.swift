//
//  Avatar.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK
struct Avatar :View{
    
    @ObservedObject
    var imageLoader                  :ImageLoader
    
    @State
    var image                        :UIImage = UIImage()
    
    private (set) var url            :String?
    private (set) var userName       :String?
    private (set) var style          :StyleConfig
    private (set) var previewImageName: String
    
    init(url          :String?,
         userName     :String?,
         fileMetaData :String? = nil,
         imageSize    :ImageSize = .SMALL,
         style        :StyleConfig = StyleConfig(),
         token        :String? = nil,
         previewImageName: String = "avatar"
    ) {
        self.url      = url
        self.userName = userName
        self.style    = style
        self.previewImageName = previewImageName
        imageLoader   = ImageLoader(url: url , fileMetaData:fileMetaData,size: imageSize, token:token)
    }
    
    struct StyleConfig{
        var cornerRadius :CGFloat = 2
        var size         :CGFloat = 64
        var textSize     :CGFloat = 24
    }
    
    var body: some View{
        if isPreview{
            Image(previewImageName)
                .resizable()
                .frame(width: style.size, height: style.size)
                .cornerRadius(style.size / style.cornerRadius)
                .scaledToFit()
        }else{
            HStack(alignment:.center){
                if url != nil{
                    Image(uiImage:imageLoader.image ?? self.image)
                        .resizable()
                        .frame(width: style.size, height: style.size)
                        .cornerRadius(style.size / style.cornerRadius)
                        .scaledToFit()
                }else{
                    Text(String(userName?.first ?? "A" ))
                        .fontWeight(.heavy)
                        .font(.system(size: style.textSize))
                        .foregroundColor(.white)
                        .frame(width: style.size, height: style.size)
                        .background(Color.blue.opacity(0.4))
                        .cornerRadius(style.size / style.cornerRadius)
                }
            }
            .onReceive(imageLoader.didChange) { image in
                self.image = image ?? UIImage()
            }
        }
    }
    
    var isPreview:Bool{
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}


struct Acatar_Previews: PreviewProvider {
    
    static var previews: some View {
        Avatar(url: nil, userName: "Hamed Hosseini" , fileMetaData:nil)
    }
}

