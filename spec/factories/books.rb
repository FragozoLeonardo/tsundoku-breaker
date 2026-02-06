# frozen_string_literal: true

FactoryBot.define do
  factory :book do
    sequence(:title) { |n| "Book Title #{n}" }
    author { "Author Name" }
    sequence(:isbn) { |n| "978#{n.to_s.rjust(10, '0')}" }
    description { "A description of the book." }
    cover_url { "http://books.google.com/cover.jpg" }
    status { :tsundoku }

    trait :reading do
      status { :reading }
    end

    trait :finished do
      status { :finished }
    end

    trait :abandoned do
      status { :abandoned }
    end

    trait :invalid do
      title { nil }
    end

    trait :processing do
      status { :processing }
    end
  end
end
