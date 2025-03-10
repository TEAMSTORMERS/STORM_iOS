//
//  CardDetailViewController.swift
//  STORM
//
//  Created by seunghwan Lee on 2020/08/19.
//  Copyright © 2020 Team STORM. All rights reserved.
//

import UIKit

enum ViewMode {
    case round
    case scrap
}

class CardDetailViewController: UIViewController {
    
    @IBOutlet weak var projectNameLabel: UILabel!
    @IBOutlet weak var roundLabel: UILabel!
    @IBOutlet weak var roundPurposeLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var drawingImageView: UIImageView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var memoView: UITextView!
    
    @IBOutlet weak var heartButton: UIButton!
    
    @IBOutlet weak var topConstOfInfoView: NSLayoutConstraint!
    
    @IBOutlet weak var memoTextLabel: UILabel!
    
    
    lazy var cards: [Card] = []
    lazy var scrappedCards: [CardItem] = []
    lazy var index: Int = 0
    lazy var isEdit: Bool = false
    lazy var viewMode: ViewMode = .round
    lazy var cardsMemo: [Int:String] = [:]
    lazy var scrapCards: [Int:Bool] = [:]
    lazy var cardIndex: Int = 0
    lazy var projectName = ""
    lazy var roundPurpose = ""
    lazy var roundNumber: Int = 0
    lazy var roundTime: Int = 0
    lazy var roundIdx: Int = 0
    lazy var projectIdx: Int = 0
    
    var topConst: CGFloat!
    
    @IBAction func didPressLeftBtn(_ sender: UIButton) {
        if isEdit == false && index >= 1{
            index -= 1
            
            UIView.transition(with: contentView, duration: 0.5, options: .transitionCurlUp, animations: nil, completion: nil)
            
            if viewMode == .round {
                updateRoundCard(index: index, priorIndex: index + 1)
            } else {
                updateScrapCard(index: index, priorIndex: index + 1)
            }
            
            if self.cardsMemo[self.index] == nil {
                self.memoTextLabel.isHidden = false
            } else {
                self.memoTextLabel.isHidden = true
            }
        }
    }
    
    @IBAction func didPressRightBtn(_ sender: UIButton) {
        if isEdit == false && index < max(cards.count - 1, scrappedCards.count - 1)  {
            
            index += 1
            
            UIView.transition(with: contentView, duration: 0.5, options: .transitionCurlDown, animations: nil, completion: nil)
            
            if viewMode == .round {
                updateRoundCard(index: index, priorIndex: index - 1)
            } else {
                updateScrapCard(index: index, priorIndex: index - 1)
            }
            
            if self.cardsMemo[self.index] == nil {
                self.memoTextLabel.isHidden = false
            } else {
                self.memoTextLabel.isHidden = true
            }
        }
    }
    
    @IBAction func didPressHeartBtn(_ sender: UIButton) {
        if scrapCards[self.index] == false {
            NetworkManager.shared.scrapCard(cardIdx: cardIndex) { (response) in
                let heartFillImage = UIImage(systemName: "heart.fill")
                sender.setImage(heartFillImage, for: .normal)
                sender.tintColor = UIColor(red: 236/255, green: 101/255, blue: 101/255, alpha: 1)
                self.scrapCards[self.index] = true
            }
        } else {
            NetworkManager.shared.cancelScrap(cardIdx: cardIndex) { (response) in
                let heartImage = UIImage(systemName: "heart")
                sender.setImage(heartImage, for: .normal)
                sender.tintColor = UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1)
                self.scrapCards[self.index] = false
            }
        }
    }
    
    @IBAction func didPressSave(_ sender: UIButton) {
        
        if memoView.text.isEmpty == true {
            return
        } else if cardsMemo[index] == nil {
            
            if viewMode == .round {
                guard let cardIdx = cards[index].card_idx else {return}
                addCardMemo(cardIndex: cardIdx)
            } else {
                addCardMemo(cardIndex: scrappedCards[index].card_idx)
            }
        } else {
            if viewMode == .round {
                guard let cardIdx = cards[index].card_idx else {return}
                modifyMemo(cardIndex: cardIdx)
            } else {
                modifyMemo(cardIndex: scrappedCards[index].card_idx)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        memoView.delegate = self
        
        memoTextLabel.font = UIFont(name: "NotoSansCJKkr-Regular", size: 13)
        
        fetchCards()
        
        shadowView.addRoundShadow(contentView: contentView, cornerRadius: 15)
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
        
        self.setNaviTitle()
        
        memoView.font = UIFont(name: "NotoSansCJKkr-Regular", size: 13)
        memoView.textColor = UIColor.placeholderColor
        
        projectNameLabel.text = projectName
        
        topConst = topConstOfInfoView.constant
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "naviBackBtn" ), style: .plain, target: self, action: #selector(back))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.memoView.endEditing(true)
        topConstOfInfoView.constant = topConst
        isEdit = false
        UIView.animate(withDuration: 0.3, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            topConstOfInfoView.constant = -keyboardHeight + 69  
            isEdit = true
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    func fetchCards() {
        if viewMode == .round {
            NetworkManager.shared.fetchCardList(projectIdx: projectIdx, roundIdx: roundIdx) { (response) in
                
                guard let cardList = response?.data?.card_list else {return}
                self.cards = cardList
                
                self.createCardMemo()
                self.createScrapCards()
                
                self.updateRoundCard(index: self.index, priorIndex: nil)
                
                self.roundLabel.text = "ROUND \(self.roundNumber)"
                self.roundPurposeLabel.text = self.roundPurpose
                self.timeLabel.text = "총 \(self.roundTime)분 소요"
                
                self.memoView.text = self.cardsMemo[self.index]
                
                if self.cardsMemo[self.index] == nil {
                    self.memoTextLabel.isHidden = false
                } else {
                    self.memoTextLabel.isHidden = true
                }
            }
        } else {
            NetworkManager.shared.fetchAllScrapCard(projectIdx: projectIdx) { (response) in
                guard let scrapCards = response?.data?.card_item else {return}
                
                self.scrappedCards = scrapCards
                
                self.createCardMemo()
                self.createScrapCards()
                
                self.updateScrapCard(index: self.index, priorIndex: nil)
                
                self.memoView.text = self.cardsMemo[self.index]
                
                if self.cardsMemo[self.index] == nil {
                    self.memoTextLabel.isHidden = false
                } else {
                    self.memoTextLabel.isHidden = true
                }
            }
        }
    }
    
    func createCardMemo() {
        if viewMode == .round {
            for index in 0..<cards.count {
                cardsMemo[index] = cards[index].memo_content
            }
        }else {
            for index in 0..<scrappedCards.count {
                cardsMemo[index] = scrappedCards[index].memo_content
            }
        }
    }
    
    func createScrapCards() {
        
        if viewMode == .round {
            for index in 0..<cards.count {
                if cards[index].scrap_flag == 1{
                    scrapCards[index] = true
                }else{
                    scrapCards[index] = false
                }
            }
        } else{
            for index in 0..<scrappedCards.count {
                scrapCards[index] = true
            }
        }
    }
    
    func updateRoundCard(index: Int, priorIndex: Int?) {
        
        guard index >= 0 && index <= cards.count - 1 else {return}
        
        let card = cards[index]
        
        guard let cardIdx = card.card_idx else {return}
        
        cardIndex = cardIdx
        
        if let priorIdx = priorIndex {
            let priorCard = cards[priorIdx]
            if let userImageUrl = card.user_img, card.user_img != priorCard.user_img {
                profileImageView.kf.setImage(with: URL(string: userImageUrl))
            }
        }else{
            if let userImageUrl = card.user_img {
                profileImageView.kf.setImage(with: URL(string: userImageUrl))
            }
        }
        
        if card.card_img == nil {
            drawingImageView.isHidden = true
            textView.isHidden = false
            
            guard let cardText = card.card_txt else {return}
            
            textView.text = cardText
            
        } else {
            textView.isHidden = true
            drawingImageView.isHidden = false
            
            guard let cardImageUrl = card.card_img else {return}
            
            drawingImageView.kf.setImage(with: URL(string: cardImageUrl))
        }
        
        memoView.text = cardsMemo[index]
        
        if scrapCards[index] == true {
            let heartFillImage = UIImage(systemName: "heart.fill")
            heartButton.setImage(heartFillImage, for: .normal)
            heartButton.tintColor = UIColor(red: 236/255, green: 101/255, blue: 101/255, alpha: 1)
        } else {
            let heartImage = UIImage(systemName: "heart")
            heartButton.setImage(heartImage, for: .normal)
            heartButton.tintColor = UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1)
        }
    }
    
    func updateScrapCard(index: Int, priorIndex: Int?) {
        
        guard index >= 0 && index <= scrappedCards.count - 1 else {return}
        
        let card = scrappedCards[index]
        
        cardIndex = card.card_idx
        
        if let priorIdx = priorIndex {
            let priorCard = scrappedCards[priorIdx]
            if let userImageUrl = card.user_img, card.user_img != priorCard.user_img {
                profileImageView.kf.setImage(with: URL(string: userImageUrl))
            }
        }else{
            if let userImageUrl = card.user_img {
                profileImageView.kf.setImage(with: URL(string: userImageUrl))
            }
        }
        
        roundLabel.text = "ROUND \(card.round_number)"
        roundPurposeLabel.text = card.round_purpose
        timeLabel.text = "총 \(Int(card.round_time))분 소요"
        
        if card.card_img == nil {
            drawingImageView.isHidden = true
            textView.isHidden = false
            
            guard let cardText = card.card_txt else {return}
            
            textView.text = cardText
            
        } else {
            drawingImageView.isHidden = false
            textView.isHidden = true
            
            
            guard let cardImageUrl = card.card_img else {return}
            
            drawingImageView.kf.setImage(with: URL(string: cardImageUrl))
            
        }
        
        memoView.text = cardsMemo[index]
        
        if scrapCards[index] == true {
            let heartFillImage = UIImage(systemName: "heart.fill")
            heartButton.setImage(heartFillImage, for: .normal)
            heartButton.tintColor = UIColor(red: 236/255, green: 101/255, blue: 101/255, alpha: 1)
        } else {
            let heartImage = UIImage(systemName: "heart")
            heartButton.setImage(heartImage, for: .normal)
            heartButton.tintColor = UIColor(red: 112/255, green: 112/255, blue: 112/255, alpha: 1)
        }
    }
    
    func addCardMemo(cardIndex: Int) {
        guard let content = memoView.text else {return}
        
        NetworkManager.shared.addCardMemo(cardIdx: cardIndex, memoContent: content) { (response) in
            
            let toastFrame = CGRect(x: self.view.center.x, y: self.view.frame.height * (280/812) , width: self.view.frame.width * (215/375), height: self.view.frame.height * (49/812))
            
            if response?.status == 200 {
                self.cardsMemo[self.index] = content
                self.showToast(message: "메모가 저장되었습니다", frame: toastFrame)
            } else {
                self.showToast(message: "메모 저장을 실패했습니다", frame: toastFrame)
            }
        }
    }
    
    func modifyMemo(cardIndex: Int) {
        guard let content = memoView.text else {return}
        
        NetworkManager.shared.modifyCardMemo(cardIdx: cardIndex, memoContent: content) { (response) in
            
            let toastFrame = CGRect(x: self.view.center.x, y: self.view.frame.height * (280/812) , width: self.view.frame.width * (215/375), height: self.view.frame.height * (49/812))
            
            if response?.status == 200 {
                self.cardsMemo[self.index] = content
                self.showToast(message: "메모가 수정되었습니다", frame: toastFrame)
            } else {
                self.showToast(message: "메모 수정을 실패했습니다", frame: toastFrame)
            }
        }
    }
}

extension CardDetailViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        memoTextLabel.isHidden = true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            memoTextLabel.isHidden = false
        }
    }
}
