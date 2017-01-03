require 'spec_helper'

describe Classroom::Database do
  let!(:initial) { Classroom::Database.organization }

  describe '.ensure!' do
    before { Classroom::Database.ensure! :foo }

    it { expect(Classroom::Database.organization).to be initial }
    it { expect(Classroom::Database.database_names).to include 'foo' }
    it { expect(with_organization(:foo) { Classroom::Database.database_names }).to include 'foo' }
  end

  describe '.connect_each!' do
    before { Classroom::Database.clean! :bar }
    before { Classroom::Database.clean! :baz }

    context 'simple usage' do
      before { with_client(:bar) { |it| it[:x].insert_one foo: 2 } }

      it { expect(with_client(:bar) { |it| it[:x].count }).to be 1 }
      it { expect(Classroom::Database.organization).to be initial }
    end

    context 'sequential usage' do
      before { with_client(:bar) { |it| it[:x].insert_one foo: 2 } }
      before { with_client(:baz) { |it| it[:y].insert_one foo: 2 } }

      it { expect(with_client(:bar) { |it| it[:x].count }).to be 1 }
      it { expect(with_client(:baz) { |it| it[:x].count }).to be 0 }

      it { expect(with_client(:bar) { |it| it[:y].count }).to be 0 }
      it { expect(with_client(:baz) { |it| it[:y].count }).to be 1 }
    end

    context 'nested usage' do
      before do
        with_client(:bar) do |bar|
          with_client(:baz) { |baz| baz[:y].insert_one foo: 2 }
          bar[:x].insert_one foo: 2
        end
      end

      it { expect(with_client(:bar) { |it| it[:x].count }).to be 1 }
      it { expect(with_client(:bar) { |it| it[:y].count }).to be 0 }

      it { expect(with_client(:baz) { |it| it[:x].count }).to be 0 }
      it { expect(with_client(:baz) { |it| it[:y].count }).to be 1 }
    end
  end
end
