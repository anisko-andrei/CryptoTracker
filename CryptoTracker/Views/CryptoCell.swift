//
//  CryptoCell.swift
//  CryptoTracker
//
//  Created by anisko on 23.05.25.
//


import UIKit
import SnapKit
import Kingfisher

final class CryptoCell: UITableViewCell {
    static let identifier = "CryptoCell"

    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let favoriteButton = UIButton(type: .system)

    var onFavoriteTapped: (() -> Void)?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(symbolLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(favoriteButton)

        iconImageView.snp.makeConstraints { make in
            make.size.equalTo(40)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(16)
        }
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(10)
            make.left.equalTo(iconImageView.snp.right).offset(12)
            make.right.lessThanOrEqualTo(favoriteButton.snp.left).offset(-8)
        }
        symbolLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.left.equalTo(nameLabel)
            make.bottom.equalToSuperview().inset(10)
        }
        priceLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(favoriteButton.snp.left).offset(-12)
        }
        favoriteButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().inset(16)
            make.width.height.equalTo(32)
        }

        iconImageView.contentMode = .scaleAspectFit
        nameLabel.font = .systemFont(ofSize: 17, weight: .medium)
        symbolLabel.font = .systemFont(ofSize: 13, weight: .regular)
        symbolLabel.textColor = .gray
        priceLabel.font = .systemFont(ofSize: 16, weight: .bold)

        favoriteButton.tintColor = .systemYellow
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)
    }

    func configure(with crypto: CryptoCurrency, isFavorite: Bool) {
        nameLabel.text = crypto.name
        symbolLabel.text = crypto.symbol?.uppercased()
        if let price = crypto.currentPrice {
            priceLabel.text = String(format: "$%.2f", price)
        } else {
            priceLabel.text = "-"
        }
        if let imageUrlString = crypto.image, let url = URL(string: imageUrlString) {
            iconImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "bitcoinsign.circle"))
        } else {
            iconImageView.image = UIImage(systemName: "bitcoinsign.circle")
        }
        let imageName = isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? .systemYellow : .systemGray3
    }

    @objc private func favoriteTapped() {
        onFavoriteTapped?()
    }
}
