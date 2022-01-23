//
//  CustomDialog.swift
//  ChatApplication
//
//  Created by Hamed on 1/15/22.
//

import SwiftUI

struct CustomDialog<DialogContent:View>: ViewModifier {
    
    @Binding
    private var isShowing:Bool
    private var dialogContent:DialogContent
    
    init(isShowing:Binding<Bool>, @ViewBuilder dialogContent:@escaping ()->DialogContent ){
        self._isShowing = isShowing
        self.dialogContent = dialogContent()
    }
    
    func body(content:Content) -> some View {
        ZStack {
            content
            if isShowing {
                // the semi-transparent overlay
                Rectangle().foregroundColor(Color.black.opacity(0.6))
                    .transition(.opacity)
                    .customAnimation(.easeInOut)
                // the dialog content is in a ZStack to pad it from the edges
                // of the screen
                ZStack {
                    dialogContent
                        .frame(width: UIScreen.main.bounds.size.width - 64, height: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .foregroundColor(.white))
                }
                .transition(.scale)
                .padding(40)
            }
        }
        .customAnimation(.spring(response: 0.5, dampingFraction: isShowing ? 0.6 : 1 , blendDuration: isShowing ? 1 : 0.2).speed(isShowing ? 1 : 3))
        .ignoresSafeArea()
    }
}

struct CustomDialog_Previews: PreviewProvider {
    static var previews: some View {
        ZStack{
            
        }
        .customDialog(isShowing: .constant(true)){
            VStack{
                Text("Hello".uppercased())
                    .fontWeight(.bold)
                Text("Message")
                
                HStack{
                    Button("Hello"){
                        
                    }.buttonStyle(PrimaryButtonStyle(bgColor:Color.black.opacity(0.1)))
                    
                    Button("Hello"){
                        
                    }.buttonStyle(PrimaryButtonStyle(bgColor:Color.pink.opacity(0.4)))
                }
            }
            .customAnimation(.spring())
            .padding()
        }
    }
}

extension View{
    
    func customDialog<DialogContent:View>(isShowing: Binding<Bool>, @ViewBuilder content:@escaping ()->DialogContent)->some View{
        self.modifier(CustomDialog(isShowing: isShowing, dialogContent: content))
    }
}
