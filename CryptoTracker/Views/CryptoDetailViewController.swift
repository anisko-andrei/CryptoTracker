//
//  CryptoDetailViewController.swift
//  CryptoTracker
//
//  Created by anisko on 25.05.25.
//

import UIKit
import Charts
import SnapKit
import Combine
import Kingfisher
import DGCharts

final class CryptoDetailViewController: UIViewController {
    private let viewModel: CryptoDetailViewModel
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let iconImageView = UIImageView()
    private let nameLabel = UILabel()
    private let symbolLabel = UILabel()
    private let priceLabel = UILabel()
    private let favoriteButton = UIButton(type: .system)
    private let periodControl = UISegmentedControl(items: CryptoDetailViewModel.Period.allCases.map { $0.rawValue })
    private let chartView = LineChartView()
    private let marketCapLabel = UILabel()
    private let marketCapRankLabel = UILabel()
    private let volumeLabel = UILabel()
    private let supplyLabel = UILabel()
    private let highLowLabel = UILabel()
    private let genesisDateLabel = UILabel()
    private let descriptionLabel = UILabel()

    init(viewModel: CryptoDetailViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        viewModel.fetchHistory(period: .day)
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = viewModel.crypto.name

        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        scrollView.addSubview(contentView)
        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        // Icon
        contentView.addSubview(iconImageView)
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.layer.cornerRadius = 25
        iconImageView.clipsToBounds = true
        iconImageView.snp.makeConstraints {
            $0.top.left.equalToSuperview().inset(20)
            $0.size.equalTo(50)
        }

        // Name & Symbol
        contentView.addSubview(nameLabel)
        nameLabel.font = .boldSystemFont(ofSize: 28)
        nameLabel.snp.makeConstraints {
            $0.top.equalTo(iconImageView)
            $0.left.equalTo(iconImageView.snp.right).offset(12)
            $0.right.equalToSuperview().inset(50)
        }

        contentView.addSubview(symbolLabel)
        symbolLabel.textColor = .gray
        symbolLabel.font = .systemFont(ofSize: 17)
        symbolLabel.snp.makeConstraints {
            $0.left.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(3)
        }

        // Favorite button
        favoriteButton.tintColor = .systemYellow
        contentView.addSubview(favoriteButton)
        favoriteButton.snp.makeConstraints { $0.centerY.equalTo(nameLabel); $0.right.equalToSuperview().inset(20); $0.width.height.equalTo(36) }
        favoriteButton.addTarget(self, action: #selector(favoriteTapped), for: .touchUpInside)

        // Price
        contentView.addSubview(priceLabel)
        priceLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        priceLabel.snp.makeConstraints {
            $0.left.equalTo(nameLabel)
            $0.top.equalTo(symbolLabel.snp.bottom).offset(8)
        }

        // Segmented control
        contentView.addSubview(periodControl)
        periodControl.selectedSegmentIndex = 0
        periodControl.addTarget(self, action: #selector(periodChanged), for: .valueChanged)
        periodControl.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.top.equalTo(priceLabel.snp.bottom).offset(16)
            $0.height.equalTo(32)
        }

        // Chart
        contentView.addSubview(chartView)
        chartView.snp.makeConstraints {
            $0.left.right.equalToSuperview().inset(20)
            $0.top.equalTo(periodControl.snp.bottom).offset(10)
            $0.height.equalTo(220)
        }

        // Market Cap & Rank
        contentView.addSubview(marketCapLabel)
        contentView.addSubview(marketCapRankLabel)
        marketCapLabel.font = .systemFont(ofSize: 16)
        marketCapRankLabel.font = .systemFont(ofSize: 16)
        marketCapLabel.snp.makeConstraints { $0.left.equalToSuperview().inset(20); $0.top.equalTo(chartView.snp.bottom).offset(20) }
        marketCapRankLabel.snp.makeConstraints { $0.left.equalToSuperview().inset(20); $0.top.equalTo(marketCapLabel.snp.bottom).offset(5) }

        // Volume
        contentView.addSubview(volumeLabel)
        volumeLabel.font = .systemFont(ofSize: 16)
        volumeLabel.snp.makeConstraints { $0.left.equalToSuperview().inset(20); $0.top.equalTo(marketCapRankLabel.snp.bottom).offset(5) }

        // Supply
        contentView.addSubview(supplyLabel)
        supplyLabel.font = .systemFont(ofSize: 16)
        supplyLabel.snp.makeConstraints { $0.left.equalToSuperview().inset(20); $0.top.equalTo(volumeLabel.snp.bottom).offset(5) }

        // High/Low 24hr
        contentView.addSubview(highLowLabel)
        highLowLabel.font = .systemFont(ofSize: 16)
        highLowLabel.snp.makeConstraints { $0.left.equalToSuperview().inset(20); $0.top.equalTo(supplyLabel.snp.bottom).offset(5) }
    }

    private func bindViewModel() {
        viewModel.$crypto
            .receive(on: DispatchQueue.main)
            .sink { [weak self] crypto in
                self?.updateCryptoUI(crypto)
            }
            .store(in: &cancellables)

        viewModel.$priceHistory
            .receive(on: DispatchQueue.main)
            .sink { [weak self] prices in
                self?.updateChart(prices: prices)
            }
            .store(in: &cancellables)

        viewModel.$isFavorite
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isFavorite in
                let imageName = isFavorite ? "star.fill" : "star"
                self?.favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
                self?.favoriteButton.tintColor = isFavorite ? .systemYellow : .systemGray3
            }
            .store(in: &cancellables)
    }

    private func updateCryptoUI(_ crypto: CryptoCurrency) {
        nameLabel.text = crypto.name
        symbolLabel.text = crypto.symbol?.uppercased()
        if let price = crypto.currentPrice {
            priceLabel.text = String(format: "$%.2f", price)
        } else {
            priceLabel.text = "-"
        }
        if let urlString = crypto.image, let url = URL(string: urlString) {
            iconImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "bitcoinsign.circle"))
        } else {
            iconImageView.image = UIImage(systemName: "bitcoinsign.circle")
        }

        marketCapLabel.text = "Market Cap: \(crypto.marketCap?.formatted() ?? "-")"
        marketCapRankLabel.text = "Rank: \(crypto.marketCapRank.map { "#\($0)" } ?? "-")"
        volumeLabel.text = "Volume: \(crypto.totalVolume?.formatted() ?? "-")"
        supplyLabel.text = "Supply: \(crypto.circulatingSupply?.formatted() ?? "-") / \(crypto.maxSupply?.formatted() ?? "-")"
        highLowLabel.text = "24h: \(crypto.low24h?.formatted() ?? "-") - \(crypto.high24h?.formatted() ?? "-")"
    }

    @objc private func favoriteTapped() {
        viewModel.toggleFavorite()
    }

    @objc private func periodChanged() {
        let p = CryptoDetailViewModel.Period.allCases[periodControl.selectedSegmentIndex]
        viewModel.fetchHistory(period: p)
    }

    private func updateChart(prices: [Double]) {
        var entries: [ChartDataEntry] = []
        for (i, price) in prices.enumerated() {
            entries.append(ChartDataEntry(x: Double(i), y: price))
        }
        let set = LineChartDataSet(entries: entries, label: "Price")
        set.colors = [.systemBlue]
        set.drawCirclesEnabled = false
        set.lineWidth = 2
        set.drawValuesEnabled = false
        set.mode = .cubicBezier

        let data = LineChartData(dataSet: set)
        chartView.data = data
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = false
        chartView.xAxis.labelPosition = .bottom
        chartView.setScaleEnabled(false)
    }
}
